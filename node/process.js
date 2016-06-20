var fs = require("fs");
var data = '';
var sourceFolder = process.env.srcFolder + "APFiles/";
var destFolder = process.env.outputFolder + "data/";
var aliasMap = {};
var aliasReverse = {};
var otherMap = {};
var otherReverse = {};
var lowestUnusedSwimmerNumber = 0;

var allMeets = [];



function processFile(sourceFile) {
    if (!sourceFile.startsWith("APFile_meet")) {
        doNextFile();
        return;
    }
    
    var meetId = sourceFile.substring(11,14);
    var fullSource = sourceFolder + sourceFile;
    var fullDest   = destFolder   + sourceFile;
    
    if (!fs.existsSync(fullSource)) {
        console.log('!! Could NOT find file: '+fullSource);
    }
    console.log("Processing: "+fullSource);
    console.log("     to --> "+fullDest);
    var readerStream = fs.createReadStream(fullSource, {
        encoding: 'utf8',
        fd: null,
    });
    
    var lineReader = require('readline').createInterface({
        input: readerStream
    });
    var count = 0;
    var first = true;
    var lineBuffer = [];

    lineReader.on('line', function (line) {
        lineBuffer.push(line);
    });

    readerStream.on('end', function() {
        parseLines(sourceFile,meetId,lineBuffer);
    });

}


function parseLines(fileName,meetId,lineBuffer) {
    console.log("PARSING: "+fileName+" had "+lineBuffer.length+" lines");
    var meetInfo = {};
    var wholeMeet = [];
    var eventInfo = {};
    var parseContext = {};
    parseContext.file = fileName;
    parseContext.meetId = meetId;
    
    
    var firstLine = lineBuffer[0];
    console.log("FIRST LINE: "+firstLine);
    
    meetInfo.year = findYear(firstLine);
    meetInfo.opponent = findOpponent(firstLine);
    meetInfo.date = findDate(firstLine);
    meetInfo.meetId = meetId;
    console.log("OPPO: "+meetInfo.opponent)
    console.log("DATE: "+meetInfo.date)
    console.log("YEAR: "+meetInfo.year);
    
    var scoreList = "";
    var lastHeader = "";
    var pos = 2;
    parseContext.line = pos;
    while (pos<lineBuffer.length) {
        var thisLine = lineBuffer[pos];
        pos++;
        if (thisLine.startsWith(" ")) {
            scoreList += thisLine;
        }
        else {
            if (scoreList.length>0) {
                appendResults(wholeMeet, meetInfo, lastHeader, scoreList, parseContext);
            }
            parseContext.line = pos;
            lastHeader = thisLine;
            scoreList = "";
        }
    }

    var fullDest   = destFolder  + "meet" + meetId + ".json";
    var writerStream = fs.createWriteStream(fullDest);
    var outObj = {};
    outObj.scores = wholeMeet;
    
    writerStream.write(JSON.stringify(outObj,null,2));
    allMeets.push(wholeMeet);

    doNextFile();
}



function findOpponent (line) {
    if (line.indexOf("Cross")>=0) {
        return "Crossgates";
    }
    else if (line.indexOf("Almad")>=0) {
        return "Almaden";
    }
    else if (line.indexOf("Pinehu")>=0) {
        return "Pinehurst";
    }
    else if (line.indexOf("Champ")>=0) {
        return "Champs";
    }
    else if (line.indexOf("Shadow")>=0) {
        return "Shadowbrook";
    }
    else if (line.indexOf("Creek")>=0) {
        return "Creekside";
    }
    else if (line.indexOf("Trial")>=0) {
        return "Trials";
    }
    else if (line.indexOf("Donut")>=0) {
        return "Trials";
    }
    else if (line.search(/Blue/i)>=0) {
        return "Trials";
    }
    else {
        console.log("CAN'T FIND OPPONENT: "+line);
        return "?OPPONENT?";
    }
}



function findYear (line) {
    var yearRes = /20\d\d/.exec(line);
    if (yearRes) {
        return yearRes[0];
    }
    else {
        console.log("NO year  in "+line);
        return "?YEAR?";
    }
}

function findDate (line) {
    var date = /(\d+)\/(\d+)\/20(\d\d)/.exec(line);
    if (!date) {
        date = /(\d+)\/(\d+)\/(\d\d)/.exec(line);
    }
    if (date) {
        var month = date[1];
        var day = date[2];
        var year = date[3];
        if (month<10) {
            month = "0"+month;
        }
        if (day<10) {
            day = "0"+day;
        }
        return "20"+year+"-"+month+"-"+day;
    }
    else {
        console.log("NO date  in "+line);
        return "0000-00-00";
    }
}

function findGender (line) {
    if (line.indexOf("Girl")>=0) {
        return "Girls";
    }
    else if (line.indexOf("Boy")>=0) {
        return "Boys";
    }
    if (line.indexOf("Men")>=0) {
        return "Boys";
    }
    if (line.indexOf("Women")>=0) {
        return "Girls";
    }
    else if (line.indexOf("Mix")>=0) {
        return "Mixed";
    }
    console.log("CAN'T FIND GENDER: "+line);
    return "?GENDER?";
}

function findStroke (line) {
    if (line.indexOf("Butter")>=0) {
        return "Butterfly";
    }
    else if (line.indexOf("Breast")>=0) {
        return "Breast";
    }
    else if (line.indexOf("Back")>=0) {
        return "Back";
    }
    else if (line.indexOf("Medle")>=0) {
        return "Medley Relay";
    }
    else if (line.indexOf("Freestyle Relay")>=0) {
        return "Freestyle Relay";
    }
    else if (line.indexOf("Freestyle")>=0) {
        return "Freestyle";
    }
    console.log("CAN'T FIND STROKE: "+line);
    return "?STROKE?";
}

function findAge (line) {
    if (line.indexOf("7-8")>=0) {
        return "7-8";
    }
    else if (line.indexOf("9-10")>=0) {
        return "9-10";
    }
    else if (line.indexOf("11-12")>=0) {
        return "11-12";
    }
    else if (line.indexOf("13-14")>=0) {
        return "13-14";
    }
    else if (line.indexOf("15-18")>=0) {
        return "15-18";
    }
    else if (line.indexOf("6 &")>=0) {
        return "6 & Under";
    }
    else if (line.indexOf("8 &")>=0) {
        return "8 & Under";
    }
    console.log("CAN'T FIND AGE: "+line);
    return "?AGE?";
}

function findTeam (line, parseContext) {
    if (line.indexOf("Otter")>=0) {
        return "Otters";
    }
    else if (line.indexOf("Teres")>=0) {
        return "Otters";
    }
    else if (line.search(/Blue/i)>=0) {
        return "Otters";
    }
    else if (line.search(/Gold/i)>=0) {
        return "Otters";
    }
    else if (line.indexOf("Almad")>=0) {
        return "Dolphins";
    }
    else if (line.indexOf("Dolph")>=0) {
        return "Dolphins";
    }
    else if (line.indexOf("Pineh")>=0) {
        return "Piranhas";
    }
    else if (line.indexOf("Piran")>=0) {
        return "Piranhas";
    }
    else if (line.indexOf("PCC")>=0) {
        return "Piranhas";
    }
    else if (line.indexOf("Creek")>=0) {
        return "Cudas";
    }
    else if (line.indexOf("Cudas")>=0) {
        return "Cudas";
    }
    else if (line.indexOf("Cross")>=0) {
        return "Gators";
    }
    else if (line.indexOf("Gators")>=0) {
        return "Gators";
    }
    else if (line.indexOf("Shadow")>=0) {
        return "Sharks";
    }
    else if (line.indexOf("Sharks")>=0) {
        return "Sharks";
    }
    else if (line.indexOf("SB")>=0) {
        return "Sharks";
    }
    else if (line.indexOf("CS-AD")>=0) {
        return "Cudas";
    }
    else {
        console.log("CAN'T FIND TEAM: "+line);
        console.log("Line: "+parseContext.line+" of file: "+parseContext.file);
        return "?TEAM?";
    }
}

function appendResults(wholeMeet, meetInfo, header, scoreList, parseContext) {
    var gender = findGender(header);
    var stroke = findStroke(header);
    var age = findAge(header);
    console.log("========="+stroke+"|"+gender+"|"+age+"|"+header);
    
    scoreList = scoreList.trim();
    if (stroke.indexOf("Relay")>0) {
        parseRelayResults(wholeMeet, meetInfo, stroke, gender, age, scoreList, parseContext);
    }
    else {
        parseIndividualResults(wholeMeet, meetInfo, stroke, gender, age, scoreList, parseContext);
    }
}
    
function parseRelayResults(wholeMeet, meetInfo, stroke, gender, age, scoreList) {
    //not doing anything for relays
}

function parseIndividualResults(wholeMeet, meetInfo, stroke, gender, age, scoreList, parseContext) {
    var start = 0;
    while (start < scoreList.length-10) {
        var pos = scanPlace(scoreList,start);
        var place = scoreList.substring(start,pos).trim();
        
        start = pos + 1;
        pos = scanName(scoreList, start);
        var rawName = parseName(scoreList,start,pos);
        
        start = pos + 1;
        pos = scoreList.indexOf(",", start);
        var team = findTeam(scoreList.substring(start, pos), parseContext);
        var alias = cleanName(rawName,team);

        start = pos + 1;
        pos = scanTime(scoreList, start, parseContext);
        var time = scoreList.substring(start,pos).trim();
        
        start = pos + 1;
        
        wholeMeet.push({
            "name"  : alias,
            "stroke":stroke,
            "age":age,
            "gender":gender,
            "date":meetInfo.date,
            "time":time,
            "place":place,
            "team":team,
            "yards":00,
            "meet":meetInfo.meetId,
            "opponent":meetInfo.opponent
        });
        //console.log("SCORE: "+alias+"|"+time+"|"+team+"|"+rawName);
    }
}





function scanPlace(scoreList,start) {
    var dotPos = scoreList.indexOf(".", start);
    var commaPos = scoreList.indexOf(",", start);
    if (commaPos < dotPos) {
        return commaPos;
    }
    return dotPos;
}

function scanName(scoreList,start) {
    var firstComma = scoreList.indexOf(",", start);
    var secondComma = scoreList.indexOf(",", firstComma+1);
    //for relay this might be a closing paren
    return secondComma;
}

function parseName(scoreList,start,end) {
    var dotPos = scoreList.indexOf(',', start);
    var lastName = scoreList.substring(start,dotPos).trim();
    var firstName = scoreList.substring(dotPos+1,end).trim();
    var newFull = cleanUp(lastName)+", "+cleanUp(firstName);
    return newFull;
}

function cleanUp(source) {
    var last = source.length;
    var dest = "";
    for (var i=0; i<last; i++) {
        var ch = source.charAt(i);
        if ( (ch>='A' && ch<='Z') || (ch>='a' && ch<='z')) {
            dest = dest + ch;
        }
    }
    return dest;
}

//These all possible
//
//     1:12.14.  
//     12.14.  
//     1:12.14;  
//     12.14;  
//     DQ.  
//     DQ;  
//     NS.  
//     NS;  
//
// and since there are other records in the line you have to find
// the closest one
//
function scanTime(scoreList,start,parseContext) {
    var rest = scoreList.substring(start);

    var dqPos = rest.search(/DQ[\.;]/i);
    var dqComp = (dqPos>0)?dqPos:rest.length;
    var nsPos = rest.search(/NS/i);
    var nsComp = (nsPos>0)?nsPos:rest.length;
    var bigPos = rest.search(/\d:\d\d.\d\d[\.;]/i);
    var bigComp = (bigPos>0)?bigPos:rest.length;
    var smPos = rest.search(/\d\d.\d\d[\.;]/i);
    var smComp = (smPos>0)?smPos:rest.length;
    
    if (bigPos<0 && smPos<0 && dqPos<0 && nsPos<0) {
        //real problem here, no digits found at all
        console.log("ERROR: Cant' Find TIME: "+rest);
        console.log("Line: "+parseContext.line+" of file: "+parseContext.file);
        return scoreList.length;
    }
    if (dqPos>0 && dqComp < bigComp && dqComp < smComp && dqComp < nsComp) {
        //looks like it is a DQ
        return start+dqPos+2;
    }
    if (nsPos>0 && nsComp < bigComp && nsComp < smComp) {
        //looks like it is a NS
        return start+nsPos+2;
    }
    if (bigPos>0 && bigComp < smComp) {
        //looks like it is a minute, second, hundredts
        return start+bigPos+7;
    }
    if (smPos>0) {
        //looks like it is a short time
        return start+smPos+5;
    }
    console.log("CAN't FIND TIME: "+rest);
    console.log("Line: "+parseContext.line+" of file: "+parseContext.file);
    return scoreList.length;
}



function cleanName(fullname, team) {
    //makeone
    if ("Otters" == team) {
        var alias = aliasMap[fullname];
        if (alias) {
            return alias;
        }
        
        var dotPos = fullname.indexOf(',');
        var lastName = fullname.substring(0,dotPos).trim();
        var firstName = fullname.substring(dotPos+1).trim();
        if (firstName.indexOf(" ")>0) {
            firstName = firstName.substring(0, firstName.indexOf(" "));
        }
        
        var cleanFullName = lastName + ", " + firstName;
        alias = aliasMap[cleanFullName];
        if (alias) {
            aliasMap[fullname] = alias;
            return alias;
        }
        
        var base = firstName + lastName.charAt(0);

        var mod = 0;
        var alias = base;
        while (aliasReverse[alias]) {
            mod++;
            alias = base + mod;
        }
        
        console.log("## newalias: "+alias+" = "+fullname);
        aliasMap[fullname] = alias;
        aliasReverse[alias] = fullname;
        return alias;
    }
    
    else {
        var alias = otherMap[fullname];
        if (alias) {
            return alias;
        }
        
        lowestUnusedSwimmerNumber++;
        alias = "Swimmer"+lowestUnusedSwimmerNumber;
        while (otherReverse[alias]) {
            lowestUnusedSwimmerNumber++;
            alias = "Swimmer"+lowestUnusedSwimmerNumber;
        }
        
        otherMap[fullname] = alias;
        otherReverse[alias] = fullname;
        return alias;
    }
    
}




aliasMap = JSON.parse(fs.readFileSync(sourceFolder+"aliases.json", 'utf8'));
otherMap = JSON.parse(fs.readFileSync(sourceFolder+"aliasesOther.json", 'utf8'));

Object.keys(aliasMap).forEach( function(key) {
    aliasReverse[ aliasMap[key] ] = key;
});
Object.keys(otherMap).forEach( function(key) {
    otherReverse[ otherMap[key] ] = key;
});

while (otherReverse["Swimmer"+lowestUnusedSwimmerNumber]) {
    lowestUnusedSwimmerNumber++;
}


var files = fs.readdirSync(sourceFolder);
var counter = 0;

function doNextFile() {
    console.log("LOOPING "+counter);
    if (counter<files.length) {
        var thisFile = files[counter];
        counter++;
        processFile(thisFile);
    }
    else {
        finishup();
    }
}

doNextFile();

function finishup() {
    console.log("FINISH UP AND WRITE OUT FILES");
    fs.createWriteStream(destFolder+"newAliases.json")
        .write(JSON.stringify(aliasMap,null,2));

    fs.createWriteStream(destFolder+"newReverse.json")
        .write(JSON.stringify(aliasReverse,null,2));

    fs.createWriteStream(destFolder+"newOtherAliases.json")
        .write(JSON.stringify(otherMap,null,2));

    fs.createWriteStream(destFolder+"newOtherReverse.json")
        .write(JSON.stringify(otherReverse,null,2));
        
    var meetList = {};
    meetList.meets = [];
    
    var sortec = {};
    allMeets.forEach( function(meet) {
        console.log("Curating ");
        var oneMeet = {};
        oneMeet.meetId = meet[0].meet;
        oneMeet.date = meet[0].date;
        oneMeet.opponent = meet[0].opponent;
        meetList.meets.push(oneMeet);
        
        meet.forEach( function(score) {
            var name = score.name;
            if (!name.startsWith("Swim")) {
                if (!sortec[name]) {
                    sortec[name] = [];
                }
                sortec[name].push(score);
            }
        });
    });
    var allAlias = {};
    allAlias.alias = Object.keys(sortec);
    
    fs.createWriteStream(destFolder+"allAlias.json")
        .write(JSON.stringify(allAlias,null,2));
    fs.createWriteStream(destFolder+"allMeets.json")
        .write(JSON.stringify(meetList,null,2));
    
    console.log("Ready to Generate");
    allAlias.alias.forEach( function(name) {
        console.log("Generating "+name);
        var temp = {};
        temp.scores = sortec[name];
        fs.createWriteStream(destFolder+name+".json")
            .write(JSON.stringify(temp,null,2));
    });
    
}

console.log("Program Ended");

