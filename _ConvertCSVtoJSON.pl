#  Script to read the swim meet results files and gather info
# expects file names to be result1.htm thru results{n}.htm

$tempFolder   =  $ENV{'tempFolder'}; 
$outputFolder =  $ENV{'outputFolder'}; 
$srcFolder    =  "$ENV{'srcFolder'}\\APFiles"; 
$srcMeets    =  "$ENV{'srcFolder'}\\MeetResults"; 

@allScoreByName = ();
@allScoreByEvent = ();

%aliasMap;
%aliasReverseMap;
$swimmerNo = 0;

($sec, $min, $hour, $mday, $mon, $year, $x, $y, $z) = localtime(time());
$mon++;
$year = $year + 1900;

$twodigitday = sprintf("%02d", $mday);
$twodigitmon = sprintf("%02d", $mon);


sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
                 
                 
sub loadAliasFile
{
    open(FILE, "$srcMeets\\aliases.txt");
    print "-----ALIASES-----\n";
    while ($line = <FILE>)
    {
        if ($line =~ /^(.*)\|(.*)$/)
        {
            $alias = trim($2);
            $name = trim($1);
            if (!($alias =~ /Swimmer\d\d\d/))
            {
                printf("%-30s --> %-20s\n", $name,  $alias);
                if (defined($aliasReverseMap{$alias}))
                {
                    print "Problem: $alias already defined as $aliasReverseMap{$alias}\n";
                }
                $aliasMap{$name} = $alias;
                $aliasReverseMap{$alias} = $name;
            }
        }
    }
    print "----- ----- -----\n";
}

sub checkForAlias {
    ($nameToCheck, $team) = @_;
    if (!defined($aliasMap{$nameToCheck})) {
        $swimmerNo++;
        if ($team eq "Otters") {
            if ($nameToCheck =~ /(\w).*,\s*(\S+)/) {
                $newalias = "$2$1";
            }
            elsif ($nameToCheck =~ /(\w).*, (.+)/) {
                $newalias = "$2$1";
            }
            else  {
                $newalias = sprintf("Swimmer%4.4d", $swimmerNo);
            }
        }
        else {
            $newalias = sprintf("Swimmer%4.4d", $swimmerNo);
        }
        $baseName = $newalias;
        $probe = 0;
        while (defined($aliasReverseMap{$newalias})) {
            print "\nProblem: $newalias already defined as $aliasReverseMap{$alias}\n";
            $probe++;
            $newalias = "$baseName$probe";
        }
        $aliasMap{$nameToCheck} = $newalias;
        $aliasReverseMap{$newalias} = $nameToCheck;
        print "\nNEW ALIAS: $nameToCheck ($team)--> $newalias";
    }
    return $aliasMap{$nameToCheck};
}


sub readAllCSVFiles {

    print "\nReading folder  $srcFolder \n";
    
    opendir(DIR, $srcFolder) or die $!;

    while (my $file = readdir(DIR)) {

        if ($file =~ /csv$/) {
            readCSV("$srcFolder\\$file");
        }
    }

    closedir(DIR);
}

sub readCSV {

    my($fileToRead) = @_;
    
    $meetId = "??";
    
    if ($fileToRead =~ /APFile_meet(\d\d\d).csv/) {
        $meetId = $1;
    }
    
    print "\n-------------------------------\nPROCESSING $fileToRead with ID:$meetId\n";
    open(FILE, $fileToRead);
    
    #first line if the name of the event
    $meetName = <FILE>;
    print "\n  The meet is named $meetName";

    $year = findYear($meetName);
    $date = findDate($meetName);
    $opponent = findOpponent($meetName);


    #second line if a duplicate
    $meetNamexx = <FILE>;
    
    $totalLine = "";
    $oldEvent = "";
    
    while ($line = <FILE>) {
        $line =~ s/\n//g;
        $line =~ s/\r//g;
        
        if ($line =~ /^ /) {
            $line =~ s/^\s+|\s+$//g;
            $totalLine = $totalLine." ".$line;
        }
        else {
            
            if (length($totalLine)>3) {
                printEvent($meetId, $oldEvent, $totalLine);
            }

            $totalLine = "";
            $oldEvent = $line;
        }
    }
    print "\n----- ----- -----\n";
    
    
}


sub printEvent {
    my($meetId, $oldEvent, $totalLine) = @_;
    $gender = findGender($oldEvent);
    $age = findAge($oldEvent);
    $stroke = findStroke($oldEvent);
    $yards = findYards($oldEvent);
    print "\n Y($year) D($date) S($stroke) G($gender) $yards Yards A($age)  -- $oldEvent";
    
    @swimmers = split(/;/, $totalLine);
    foreach my $number (@swimmers) {
        $number =~ s/^\s+|\s+$//g;
        
        #replace 
        $number =~ s/Unknown Unknown/Unknown, Unknown/g;
        
        
        if ($number  =~ /^(\d+|--)\. (.*) \((.+, .+) (\d\d?), (.+, .+) (\d\d?), (.+, .+) (\d\d?), (.+, .+) (\d\d?)\), (.+)$/) {
            $position = $1;
            $time = $11;
            $team = findTeam($2);
            $fullName = $3;
            $alias = checkForAlias($fullName, $team);
            push @allScoreByName, "$alias|$stroke|$age|$gender|$date|$time|$position|$team|$yards|$opponent|$meetId";
            push @allScoreByEvent, "$date|$stroke|$age|$gender|$position|$time|$alias|$team|$yards|$opponent|$meetId";
            $fullName = $5;
            $alias = checkForAlias($fullName, $team);
            push @allScoreByName, "$alias|$stroke|$age|$gender|$date|$time|$position|$team|$yards|$opponent|$meetId";
            push @allScoreByEvent, "$date|$stroke|$age|$gender|$position|$time|$alias|$team|$yards|$opponent|$meetId";
            $fullName = $7;
            $alias = checkForAlias($fullName, $team);
            push @allScoreByName, "$alias|$stroke|$age|$gender|$date|$time|$position|$team|$yards|$opponent|$meetId";
            push @allScoreByEvent, "$date|$stroke|$age|$gender|$position|$time|$alias|$team|$yards|$opponent|$meetId";
            $fullName = $9;
            $alias = checkForAlias($fullName, $team);
            push @allScoreByName, "$alias|$stroke|$age|$gender|$date|$time|$position|$team|$yards|$opponent|$meetId";
            push @allScoreByEvent, "$date|$stroke|$age|$gender|$position|$time|$alias|$team|$yards|$opponent|$meetId";
        }
        elsif ($number  =~ /^(\d+|--)\. (.*) \((.*)\) (.+)$/) {
            $position = $1;
            print ("\n#   1-$1 2-$2 3-$3 4-$4");
        }
        elsif ($number  =~ /^(.*)\((.*)\)(.*)$/) {
            $position = $1;
            print ("\n!   1-$1 2-$2 3-$3 4-$4");
        }
        elsif ($number  =~ /^(\d+|--)\. (.*), (.*), (.*), (.*)$/) {
            $position = $1;
            $fullName = "$2, $3";
            $time = $5;
            $team = findTeam($4);
            $alias = checkForAlias($fullName, $team);
            push @allScoreByName, "$alias|$stroke|$age|$gender|$date|$time|$position|$team|$yards|$opponent|$meetId";
            push @allScoreByEvent, "$date|$stroke|$age|$gender|$position|$time|$alias|$team|$yards|$opponent|$meetId";
        }
        else {
            #print "\nNO MATCH: ($number)";
        }
    }
}



sub findGender {
    my($name) = @_;
    if ($name =~ /Girl/) {
        return "Girls";
    }
    elsif ($name =~ /Boy/) {
        return "Boys";
    }
    elsif ($name =~ /Mixed/) {
        return "Mixed";
    }
    else {
        return "$name";
    }
}

sub findAge {
    my($name) = @_;
    if ($name =~ /(\d+)-(\d+)/) {
        return "$1-$2";
    }
    if ($name =~ /6 & Under/) {
        return "6 & Under";
    }
    if ($name =~ /8 & Under/) {
        return "8 & Under";
    }
    return "?AGE?";
}

sub findStroke {
    my($name) = @_;
    if ($name =~ /Freestyle Relay/) {
        return "Freestyle Relay"
    }
    if ($name =~ /Freestyle/) {
        return "Freestyle";
    }
    if ($name =~ /Back/) {
        return "Back";
    }
    if ($name =~ /Butter/) {
        return "Butterfly";
    }
    if ($name =~ /Breas/) {
        return "Breast";
    }
    if ($name =~ /Medley Relay/) {
        return "Medley Relay"
    }
    return "?Stroke?"
}

sub findYards {
    my($name) = @_;
    if ($name =~ /(\d\d\d?) Yard/) {
        return "$1";
    }
    return "?Yards?"
}



sub findYear {
    my($name) = @_;
    if ($name =~ /(2\d\d\d) /) {
        return "$1";
    }
    return "$name";
}

sub findDate {
    my($name) = @_;
    if ($name =~ / (\d\d)\/(\d\d)\/20(\d\d)/   ) {
        return "20$3-$1-$2";
    }
    if ($name =~ / (\d)\/(\d\d)\/20(\d\d)/   ) {
        return "20$3-0$1-$2";
    }
    if ($name =~ / (\d)\/(\d)\/20(\d\d)/   ) {
        return "20$3-0$1-0$2";
    }
    if ($name =~ / (\d\d)\/(\d\d)\/(\d\d)/   ) {
        return "20$3-$1-$2";
    }
    if ($name =~ / (\d)\/(\d\d)\/(\d\d)/   ) {
        return "20$3-0$1-$2";
    }
    if ($name =~ / (\d\d)\/(\d)\/(\d\d)/   ) {
        return "20$3-$1-0$2";
    }
    if ($name =~ / (\d)\/(\d)\/(\d\d)/   ) {
        return "20$3-0$1-0$2";
    }
    return "?DATE?"
}


sub findTeam {
    my($name) = @_;
    if ($name =~ /Otters/   ) {
        return "Otters";
    }
    if ($name =~ /Teresa/   ) {
        return "Otters";
    }
    if ($name =~ /BLUE/   ) {
        return "Otters";
    }
    if ($name =~ /GOLD/   ) {
        return "Otters";
    }
    if ($name =~ /Gators/   ) {
        return "Gators";
    }
    if ($name =~ /Crossg/   ) {
        return "Gators";
    }
    if ($name =~ /Cudas/   ) {
        return "Cudas";
    }
    if ($name =~ /Creek/   ) {
        return "Cudas";
    }
    if ($name =~ /Piran/   ) {
        return "Piranhas";
    }
    if ($name =~ /Pinehu/   ) {
        return "Pirhanua";
    }
    if ($name =~ /PCC/   ) {
        return "Pirhanua";
    }
    if ($name =~ /Shark/   ) {
        return "Sharks";
    }
    if ($name =~ /Shadow/   ) {
        return "Sharks";
    }
    if ($name =~ /SB/   ) {
        return "Sharks";
    }
    if ($name =~ /Dolphin/   ) {
        return "Dolphins";
    }
    if ($name =~ /Almade/   ) {
        return "Dolphins";
    }
    return "?TEAM-$name?"
}


sub findOpponent {
    my($name) = @_;
    if ($name =~ /Champ/   ) {
        return "Champs";
    }
    if ($name =~ /Crossg/   ) {
        return "Crossgate";
    }
    if ($name =~ /Creek/   ) {
        return "Creekside";
    }
    if ($name =~ /Pinehu/   ) {
        return "Pinehurst";
    }
    if ($name =~ /Shadow/   ) {
        return "Shadowbrook";
    }
    if ($name =~ /Almaden/   ) {
        return "Almaden";
    }
    if ($name =~ /Donut/   ) {
        return "Trials";
    }
    if ($name =~ /Trial/   ) {
        return "Trials";
    }
    if ($name =~ /Blue/   ) {
        return "Trials";
    }
    return "?OPPO-$name?"
}



sub genMeetFiles {

    @allScoreByEvent = sort @allScoreByEvent;
    my $commaTrick = "";
    
    my $lastDate = "";
    my $isPrinting = 0;
    
    print "Making Swimmer JSON for $alias ($fullName)\n";
    
    print "\n{scores:[";
    
    foreach my $aline (@allScoreByEvent) {
        my($date, $stroke, $age, $gender, $position, $time, $alias, $team, $yards, $opponent, $meetId) = split(/\|/, $aline);
        if ($lastDate ne $date) {
            if ($isPrinting) {
                print OUTFILE "\n]}\n\n\n";
                close(OUTFILE);
            }
            $isPrinting = 1;
            if ($isPrinting) {
                open(OUTFILE, ">$outputFolder\\data\\meet$meetId.json");
                print "\nMaking MEET JSON for Meet$meetId on $date with $opponent";
                print OUTFILE "\n{\"scores\":[";
                $commaTrick = "";
            }
            $lastDate = $date;
        }
        if ($isPrinting) {
            print OUTFILE "$commaTrick\n  {";
            print OUTFILE "\n    \"name\":\"$alias\",";
            print OUTFILE "\n    \"stroke\":\"$stroke\",";
            print OUTFILE "\n    \"age\":\"$age\",";
            print OUTFILE "\n    \"gender\":\"$gender\",";
            print OUTFILE "\n    \"date\":\"$date\",";
            print OUTFILE "\n    \"time\":\"$time\",";
            print OUTFILE "\n    \"place\":\"$position\",";
            print OUTFILE "\n    \"team\":\"$team\",";
            print OUTFILE "\n    \"yards\":$yards,";
            print OUTFILE "\n    \"meet\":\"$meetId\",";
            print OUTFILE "\n    \"opponent\":\"$opponent\"";
            print OUTFILE "\n  }";
            $commaTrick = ",";
        }
    }
    if ($isPrinting) {
        print OUTFILE "\n]}\n\n\n";
        close(OUTFILE);
    }
    
}


sub genSwimmerFiles {

    @allScoreByName = sort @allScoreByName;
    my $commaTrick = "";
    
    my $lastAlias = "";
    my $isPrinting = 0;
    
    print "Making Swimmer JSON for $alias ($fullName)\n";
    
    print "\n{scores:[";
    
    foreach my $aline (@allScoreByName) {
        #print "\n+  $aline";
        my($alias, $stroke, $age, $gender, $date, $time, $position, $team, $yards, $opponent, $meetId) = split(/\|/, $aline);
        if ($lastAlias ne $alias) {
            if ($isPrinting) {
                print OUTFILE "\n]}\n\n\n";
                close(OUTFILE);
            }
            $isPrinting = 0;
            if ($team eq "Otters") {
                $isPrinting = 1;
            }
            if ($isPrinting) {
                open(OUTFILE, ">$outputFolder\\data\\$alias.json");
                print "\nMaking Swimmer JSON for $alias ($aliasReverseMap{$alias})";
                print OUTFILE "\n{\"scores\":[";
                $commaTrick = "";
            }
            $lastAlias = $alias;
        }
        if ($isPrinting) {
            print OUTFILE "$commaTrick\n  {";
            print OUTFILE "\n    \"name\":\"$alias\",";
            print OUTFILE "\n    \"stroke\":\"$stroke\",";
            print OUTFILE "\n    \"age\":\"$age\",";
            print OUTFILE "\n    \"gender\":\"$gender\",";
            print OUTFILE "\n    \"date\":\"$date\",";
            print OUTFILE "\n    \"time\":\"$time\",";
            print OUTFILE "\n    \"place\":\"$position\",";
            print OUTFILE "\n    \"team\":\"$team\",";
            print OUTFILE "\n    \"yards\":$yards,";
            print OUTFILE "\n    \"meet\":\"$meetId\",";
            print OUTFILE "\n    \"opponent\":\"$opponent\"";
            print OUTFILE "\n  }";
            $commaTrick = ",";
        }
    }
    if ($isPrinting) {
        print OUTFILE "\n]}\n\n\n";
        close(OUTFILE);
    }
    
}


print "\n--- START ---";
loadAliasFile();
readAllCSVFiles();
genMeetFiles();
genSwimmerFiles();
print "\n--- RUN END ---\n";
