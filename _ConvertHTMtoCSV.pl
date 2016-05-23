#  Script to read the swim meet results files and gather info
# expects file names to be result1.htm thru results{n}.htm

$tempFolder   =  $ENV{'tempFolder'}; 
$outputFolder =  $ENV{'outputFolder'}; 
$srcFolder    =  "$ENV{'srcFolder'}\\MeetResults"; 

%mapNumberName;
%mapKeyPlace;
%mapKeySeed;
%mapKeyFinal;
%mapNameKey;
%mapNameAge;
%mapNameNumber;
%mapMeetNumberName;
%mapMeetKeys;
%mapIsRelay;
%mapSwam2004;
%aliasMap;
%aliasReverseMap;
$swimmerNo = 0;

($sec, $min, $hour, $mday, $mon, $year, $x, $y, $z) = localtime(time());
$mon++;
$year = $year + 1900;

$twodigitday = sprintf("%02d", $mday);
$twodigitmon = sprintf("%02d", $mon);

$pageCloseText = "<hr><a href=\"index.htm\">List of All Swimmers</a> &nbsp;\n".
                 "<a href=\"SeaOtterMain.htm\">Schedule & Results Home</a> &nbsp; \n".
                 "<a href=\"http://stseaotters.com\">Sea Otters Home</a> &nbsp; \n".
                 "<font size=-1>(Page updated $year\-$twodigitmon\-$twodigitday, Keith Swenson)</font>\n".
                 "</body></html>\n";

sub loadAliasFile
{
    open(FILE, "$srcFolder\\aliases.txt");
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

sub checkForAlias
{
    ($nameToCheck) = @_;
    if (!defined($aliasMap{$nameToCheck}))
    {
        $swimmerNo++;
        $newalias = sprintf("Swimmer%4.4d", $swimmerNo);
        while (defined($aliasReverseMap{$newalias}))
        {
            print "Problem: $newalias already defined as $aliasReverseMap{$alias}\n";
            $newalias = $newalias."0";
        }
        $aliasMap{$nameToCheck} = $newalias;
        $aliasReverseMap{$newalias} = $nameToCheck;
        print ": $nameToCheck --> $newalias\n";
    }
    return $aliasMap{$nameToCheck};
}


sub GatherFromFile
{
    ($filename, $meet, $style, $meetName) = @_;

    $mapMeetNumberName{$meet} = $meetName;
    $meetString = $meet;
    $latestMeet = $meet;
    $mapMeetNumberStyle{$meet} = $style;
    $is2004 = ($style ne "oldmeet");

    print "READING/PARSING: {$filename}\n";
    open(FILE, "<$srcFolder\\$filename");
    $lastEvent = 0;
    $lineCount = 0;

    while ($line = <FILE>)
    {
        $lineCount++;
        if ($line =~ /^====/)
        {
            next;   #skip the breakers
        }
        # old format of event line
        if ($line =~ /^Event (\d*)  (.*)$/)
        {
            $eventNumber = sprintf("%2d", $1);
            #print "Found Event {$eventNumber} {$2}\n";
            $eventName = $2;
            $mapNumberName{$eventNumber} = $eventName;
            next;
        }
        #new format of event line with bold
        if ($line =~ /^.b.Event (\d*)  (.*)..b.$/)
        {
            $eventNumber = sprintf("%2d", $1);
            #print "Found Event {$eventNumber} {$2}\n";
            $eventName = $2;
            $mapNumberName{$eventNumber} = $eventName;
            next;
        }
        if ($line =~ /^</)
        {
            next;  #skip any other line with formatting
        }

        # in case some white spaces were stripped from the end of the lines
        $line =~ s/\n/ /g;
        $line = $line."                ";

        if ($line =~ /^ ([- ][\d-]) (................................)                 (........)   (........)/)
        {
            #print "found relay Start: $1 {$2} {$3/$4}\n";
            $relayPlace = $1;
            $relayTeam = $2;
            $relaySeedTime = $3;
            $relayFinalTime = $4;
            next;
        }

        # relay members
        if ($line =~ /^     [13]\) (...............................) [24]\) (.*)/)
        {
            if ($lastEvent != $eventNumber)
            {
                $lastEvent = $eventNumber;
                $position = 0;
            }
            $eventString = sprintf("%2d", int($eventNumber));
            $nameAndAge1 = $1;
            $nameAndAge2 = $2;

            $position++;
            $posString = sprintf("%2d", $position);
            ProcessRelaySwimmer($posString, $nameAndAge1, $meetString, $eventString, $lineCount);
            $position++;
            $posString = sprintf("%2d", $position);
            ProcessRelaySwimmer($posString, $nameAndAge2, $meetString, $eventString, $lineCount);
            next;
        }

        # check for a event place line
        if ($line =~ /^ ([ \d-][\d-]) (.........................) (..) (....................) (.......)    (.......)/)
        {
            if ($lastEvent != $eventNumber)
            {
                $lastEvent = $eventNumber;
                $position = 0;
            }
            $position++;
            $posString = sprintf("%2d", $position);
            $eventString = sprintf("%2d", int($eventNumber));

            $place = $1;
            $name = trim($2);
            $age = $3;
            $team = $4;
            $seedTime = $5;
            $finalTime = $6;

            #suppress scratches (we don't care about them...)
            if ($finalTime =~ /SCR/) {
                next;
            }

            if ($name =~ /^(.*\S+)\s+$/)
            {
                $name = trim($1);
            }
            #print "$eventName: place=$place {$name}\n";
            $key = "$name|$eventString|$meetString";
            $otherKey = "$meetString|$eventString|$posString|$name";
            $mapKeyPlace{$key} = $place;
            $mapKeySeed{$key} = $seedTime;
            $mapKeyFinal{$key} = $finalTime;
            $mapKeyTeam{$key} = $team;
            $mapMeetKeys{$otherKey} = $key;
            $mapNameAge{"$name $meet"}=$age;
            #print "  -- name=$name meet=$meet age=$age\n";
            if ($team =~ /Sea Otters/ || $team =~ /GOLD/ || $team =~ /BLUE/)
            {
                $mapNameKey{$name} = $key;
                if ($is2004) {
                    $mapSwam2004{$name} = $name;
                }
            }
        }

    }
    close(FILE);
}


sub ProcessRelaySwimmer
{
    ($posit, $nameAndAge, $meetString, $eventString, $lineCount) = @_;
    if ($nameAndAge =~ /^(.*) [MW]?(\d\d?) *$/)
    {
        $name = trim($1);
        $age = $2;
    }
    else
    {
        $name = "Unknown Unknown";
        $age = 0;
        print "$lineCount. Name and age not found: {$nameAndAge} in $eventString\n";
    }
    #print "  -- event=$eventString place=$relayPlace  $posit $name\n";
    $key = "$name|$eventString|$meetString";
    $otherKey = "$meetString|$eventString|$posit|$relayTeam";
    $mapKeyPlace{$key} = $relayPlace;
    $mapKeySeed{$key} = $relaySeedTime;
    $mapKeyFinal{$key} = $relayFinalTime;
    $mapKeyTeam{$key} = $relayTeam;
    $mapMeetKeys{$otherKey} = $key;
    if ($relayTeam =~ /^Santa/ || $relayTeam =~ /^gold/ || $relayTeam =~ /^blue/)
    {
        $mapNameKey{$name} = $key;
    }
}



sub CreateSwimmerPage
{
    ($number, $name) = @_;
    $alias = checkForAlias($name);
}

sub CreateMeetPage
{
    ($meet) = @_;
    print "Making meet page for $meet\n";

    dumpAPFileOut($meet);
    dumpMeetJSONOut($meet);
}

sub dumpAPFileOut
{
    ($meet) = @_;
    print "Making AP File for $meet\n";

    open(OUTFILE, ">$tempFolder\\APFile_meet$meet.csv");
    print OUTFILE "$mapMeetNumberName{$meet}\n";
    print OUTFILE "$mapMeetNumberName{$meet}";
    $lastEvent = 0;
    $relayCount = 0;
    $relayNames = "";
    $linePos = 0;

    foreach $mkey (sort keys %mapMeetKeys)
    {
        $skey = $mapMeetKeys{$mkey};
        ($sname, $eventNumber, $smeet) = split(/\|/, $skey);
        $alias = checkForAlias($sname);
        if ($smeet == $meet)
        {
            $locator = "Event".int($eventNumber);
            $eventName = trim($mapNumberName{$eventNumber});
            $trimPlace = trim($mapKeyPlace{$skey});
            $trimTeam = trim($mapKeyTeam{$skey});
            $trimFinal = trim($mapKeyFinal{$skey});
            $age = 0 + $mapNameAge{"$sname $meet"};
            if ($lastEvent != $eventNumber)
            {
                print OUTFILE "\n$eventName:\n ";
                $linePos = 1;
                $lastEvent = $eventNumber;
            }
            if ($eventName =~ /Relay/) {

                if ($relayCount == 0) {
                    $relayNames = "$sname $age";
                }
                else {
                    $relayNames = "$relayNames, $sname $age";
                }
                $relayCount = $relayCount + 1;
                if ($relayCount>3) {
                    $record = "$trimPlace. $trimTeam ($relayNames), $trimFinal; ";
                    for (my $charNo = 0; $charNo < length($record); $charNo++) {
                        $oneChar = substr ($record, $charNo, 1);
                        print OUTFILE $oneChar;
                        if (($oneChar eq " ") && ($linePos>70)) {
                            print OUTFILE "\n ";
                            $linePos = 0;
                        }
                        $linePos++;
                    }
                    $relayCount = 0;
                }
            }
            else {
                $record = "$trimPlace. $sname, $trimTeam, $trimFinal; ";
                for (my $charNo = 0; $charNo < length($record); $charNo++) {
                    $oneChar = substr ($record, $charNo, 1);
                    print OUTFILE $oneChar;
                    if ($oneChar eq " " && $linePos>70) {
                        print OUTFILE "\n ";
                        $linePos = 0;
                    }
                    $linePos++;
                }
            }

        }
    }
    close(OUTFILE);
}

sub dumpMeetJSONOut
{
    ($meet) = @_;
    print "Making JSON File for $meet\n";

    open(OUTFILE, ">$tempFolder\\Meet$meet.json");
    print OUTFILE "[\n";
    $lastEvent = 0;
    $relayCount = 0;
    $relayNames = "";
    $linePos = 0;
    $needClose = 0;
    $notFirstRec = 0;

    foreach $mkey (sort keys %mapMeetKeys)
    {
        $skey = $mapMeetKeys{$mkey};
        ($sname, $eventNumber, $smeet) = split(/\|/, $skey);
        $alias = checkForAlias($sname);
        if ($smeet == $meet)
        {
            $locator = "Event".int($eventNumber);
            $eventName = trim($mapNumberName{$eventNumber});
            $trimPlace = trim($mapKeyPlace{$skey});
            $trimTeam = trim($mapKeyTeam{$skey});
            $trimFinal = trim($mapKeyFinal{$skey});
            $age = 0 + $mapNameAge{"$sname $meet"};
            if ($lastEvent != $eventNumber)
            {
                if ($notFirstRec != 0) {
                    print OUTFILE "      }\n";
                }
                if ($needClose != 0) {
                    print OUTFILE "    ]\n";
                    print OUTFILE "  },\n";
                }
                print OUTFILE "  {\n";
                print OUTFILE "    \"eventNo\": $eventNumber,\n ";
                print OUTFILE "    \"eventName\": \"$eventName\",\n ";
                print OUTFILE "    \"times\": [\n ";
                $linePos = 1;
                $lastEvent = $eventNumber;
                $needClose = 1;
            }
            else {
                if ($notFirstRec != 0) {
                    print OUTFILE "      },\n";
                }
            }
            $notFirstRec = 1;
            print OUTFILE "      {\n";
            print OUTFILE "        \"place\": \"$trimPlace\",\n ";
            print OUTFILE "        \"swimmer\": \"$alias\",\n ";
            print OUTFILE "        \"team\": \"$trimTeam\",\n ";
            print OUTFILE "        \"final\": \"$trimFinal\",\n ";
            print OUTFILE "        \"age\": \"$age\"\n ";
        }
    }
    print OUTFILE "      }\n";
    print OUTFILE "    ]\n";
    print OUTFILE "  }\n";
    print OUTFILE "]\n";
    close(OUTFILE);
}


sub dumpAllMapMeetKeys
{
    print "Dumping all keys out\n";

    open(OUTFILE, ">$tempFolder\\DebugMapKeyDump.txt");
    print OUTFILE "DebugMapKeyDump\n";
    $lastEvent = 0;
    $relayCount = 0;
    $relayNames = "";
    $linePos = 0;

    foreach $mkey (sort keys %mapMeetKeys)
    {
        print OUTFILE "$mkey|#|$mapMeetKeys{$mkey}\n";
    }
    close(OUTFILE);
}

sub CreateFakePage
{
    ($meet, $meetName) = @_;
    print "NO fake page for $meet\n";
}

sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub CreateAlphaPage
{
    print "NO Alphabetical Page\n";

}


print "--- RUN START ---\n";
loadAliasFile();


#Earlier Meets

sub gatherEarlyResults
{
    GatherFromFile("results01.htm",                    "001", "oldmeet", "2001 Crossgate vs.Santa Teresa - 6/9/01");
    GatherFromFile("results02.htm",                    "002", "oldmeet", "2001 Santa Teresa @ Almaden - 6/16/01");
    GatherFromFile("results03.htm",                    "003", "oldmeet", "2001 Creekside vs.Santa Teresa - 6/23/01");
    GatherFromFile("results04.htm",                    "004", "oldmeet", "2001 Santa Teresa @ Shadowbrook - 6/30/01");
    GatherFromFile("results05.htm",                    "005", "oldmeet", "2001 Santa Teresa vs. Pinehurst - 7/14/01");
    GatherFromFile("results06.htm",                    "006", "oldmeet", "2001 Cabana League Championships - 7/21/01");
    GatherFromFile("results07.htm",                    "007", "oldmeet", "2002 Donut Meet - 5/11/02");
    GatherFromFile("results08.htm",                    "008", "oldmeet", "2002 Blue/Gold Meet - 5/31/02");
    GatherFromFile("results09.htm",                    "009", "oldmeet", "2002 Santa Teresa @ Pinehurst - 6/08/02");
    GatherFromFile("results10.htm",                    "010", "oldmeet", "2002 Santa Teresa @ Crossgate - 6/15/02");
    GatherFromFile("results11.htm",                    "011", "oldmeet", "2002 Santa Teresa vs. Almaden - 6/22/02");
    GatherFromFile("results12.htm",                    "012", "oldmeet", "2002 Santa Teresa @ Creekside - 6/29/02");
    GatherFromFile("results13.htm",                    "013", "oldmeet", "2002 Santa Teresa vs. Shadowbrook - 7/13/02");
    GatherFromFile("results14.htm",                    "014", "oldmeet", "2002 Cabana League Championships - 7/20/02");
    GatherFromFile("Results2003a.Donut.htm",           "015", "oldmeet", "2003 Donut Meet - 5/10/03");
    GatherFromFile("Results2003b.PinehurstTrials.htm", "016", "oldmeet", "2003 Pinehurst Trials - 5/31/03");
    GatherFromFile("Results2003c.Shadowbrook.htm",     "017", "oldmeet", "2003 Santa Teresa @ Shadowbrook - 6/09/03");
    GatherFromFile("Results2003d.Pinehurst.htm",       "018", "oldmeet", "2003 Santa Teresa vs. Pinehurst - 6/14/03");
    GatherFromFile("Results2003e_XGate.htm",           "019", "oldmeet", "2003 Santa Teresa vs. Crossgate - 6/21/03");
    GatherFromFile("Results2003f_Almaden.htm",         "020", "oldmeet", "2003 Santa Teresa @ Almaden - 6/28/03");
    GatherFromFile("Results2003g_Creekside.htm",       "021", "oldmeet", "2003 Santa Teresa vs. Creekside - 7/12/03");
    GatherFromFile("Results2003h_Champs.htm",          "022", "oldmeet", "2003 Cabana League Championships - 7/19/03");
    GatherFromFile("Results2004a.Donut.htm",           "023", "oldmeet", "2004 Donut Meet - 5/20/04");
    GatherFromFile("Results2004b.Creekside.htm",       "024", "oldmeet", "2004 Santa Teresa @ Creekside - 6/05/04");
    GatherFromFile("Results2004c.Shadowbrook.htm",     "025", "oldmeet", "2004 Santa Teresa vs. Shadowbrook - 6/12/04");
    GatherFromFile("Results2004d.Pinehurst.htm",       "026", "oldmeet", "2004 Santa Teresa @ Pinehurst - 6/19/04");
    GatherFromFile("Results2004e.Crossgates.htm",      "027", "oldmeet", "2004 Santa Teresa @ Crossgates - 6/26/04");
    GatherFromFile("Results2004f.Almaden.htm",         "028", "oldmeet", "2004 Santa Teresa vs. Almaden - 7/10/04");
    GatherFromFile("Results20040717_Champs.htm",       "029", "oldmeet", "2004 Cabana League Championships - 7/17/04");
    #GatherFromFile("Results20050521_TimedTrials.htm",  "030", "oldmeet", "2005 Donut Meet - 5/21/05");
    #this meet has firstname lastname instead of lastname, firstname
    GatherFromFile("Results20050604_Almaden.htm",      "031", "oldmeet", "2005 Santa Teresa @ Almaden - 6/04/05");
    GatherFromFile("Results20050611_Creekside.htm",    "032", "oldmeet", "2005 Santa Teresa vs. Creekside - 6/11/05");
    GatherFromFile("Results20050618_Shadow.htm",       "033", "oldmeet", "2005 Santa Teresa @ Shadow Brook - 6/18/05");
    GatherFromFile("Results20050625_Pinehurst.htm",    "034", "oldmeet", "2005 Santa Teresa vs. Pinehurst - 6/25/05");
    GatherFromFile("Results20050709_XGate.htm",        "035", "oldmeet", "2005 Santa Teresa vs. Crossgate - 7/09/05");
    GatherFromFile("Results20050716_Champs.htm",       "036", "oldmeet", "2005 Cabana League Championships - 7/16/05");
    GatherFromFile("Results20060520_timetrials.htm",   "037", "oldmeet", "2006 Donut Meet - 5/20/06");
    GatherFromFile("Results20060603_XGate.htm",        "038", "oldmeet", "2006 Santa Teresa @ Crossgate - 6/03/06");
    GatherFromFile("Results20060610_Almaden.htm",      "039", "oldmeet", "2006 Santa Teresa vs. Almaden - 6/10/06");
    GatherFromFile("Results20060617_CreekSide.htm",    "040", "oldmeet", "2006 Santa Teresa @ Creekside - 6/17/06");
    GatherFromFile("Results20060624_ShadowBrook.htm",  "041", "oldmeet", "2006 Santa Teresa vs. Shadow Brook - 6/24/06");
    GatherFromFile("Results20060708_Pinehurst.htm",    "042", "oldmeet", "2006 Santa Teresa @ Pinehurst - 7/08/06");
    GatherFromFile("Results20060715_Champs.htm",       "043", "oldmeet", "2006 Cabana League Championships - 7/15/06");
    GatherFromFile("Results20070602_timetrials.htm",   "044", "oldmeet", "2007 Donut Meet - 6/02/07");
    GatherFromFile("Results20070609_Pinehurst.htm",    "045", "oldmeet", "2007 Santa Teresa vs. Pinehurst - 6/09/07");
    GatherFromFile("Results20070616_XGate.htm",        "046", "oldmeet", "2007 Santa Teresa vs. Crossgate - 6/16/07");
    GatherFromFile("Results20070623_Almaden.htm",      "047", "oldmeet", "2007 Santa Teresa @ Almaden - 6/23/07");
    GatherFromFile("Results20070630_Creekside.htm",    "048", "oldmeet", "2007 Santa Teresa vs Creekside - 6/30/07");
    GatherFromFile("Results20070707_Shadowbrook.htm",  "049", "oldmeet", "2007 Santa Teresa @ Shadowbrook - 7/07/07");
    GatherFromFile("Results20070714_Champs.htm",       "050", "oldmeet", "2007 Cabana League Championships - 7/14/07");
    GatherFromFile("Results20080531_timetrials.htm",   "051", "oldmeet", "2008 Time Trials - 5/31/08");
    GatherFromFile("Results20080606_shadowbrook.htm",  "052", "oldmeet", "2008 Santa Teresa @ Shadowbrook - 6/07/08");
    GatherFromFile("Results20080614_Pinehurst.htm",    "053", "oldmeet", "2008 Santa Teresa @ Pinehurst - 6/14/08");
    GatherFromFile("Results20080621_Crossgate.htm",    "054", "oldmeet", "2008 Santa Teresa vs. Crossgate - 6/21/08");
    GatherFromFile("Results20080628_Almaden.htm",      "055", "oldmeet", "2008 Santa Teresa vs. Almaden - 6/28/08");
    GatherFromFile("Results20080712_Creekside.htm",    "056", "oldmeet", "2008 Santa Teresa @ Creekside - 7/12/08");
    GatherFromFile("Results20080719_Champs.htm",       "057", "oldmeet", "2008 Cabana League Championships - 7/19/08");
    GatherFromFile("Results20090530_TimeTrials.htm",   "058", "oldmeet", "2009 Time Trials - 5/30/09");
    GatherFromFile("Results20090606_Cudas.htm",        "059", "oldmeet", "2009 Santa Teresa vs. Creekside - 6/06/09");
    GatherFromFile("Results20090613_Shadowbrook.htm",  "060", "oldmeet", "2009 Santa Teresa @ Shadowbrook - 6/13/09");
    GatherFromFile("Results20090620_Pines.htm",        "061", "oldmeet", "2009 Santa Teresa vs Pinehurst - 6/20/09");
    GatherFromFile("Results20090627_XGate.htm",        "062", "oldmeet", "2009 Santa Teresa vs Crossgates - 6/27/09");
    GatherFromFile("Results20090711_Almaden.htm",      "063", "oldmeet", "2009 Santa Teresa @ Almaden - 7/11/09");
    GatherFromFile("Results20090718_Champs.htm",       "064", "oldmeet", "2009 Cabana League Championships - 7/18/09");
}

sub gatherMidResults
{
    GatherFromFile("Results20100522_Donut.htm",        "065", "oldmeet","2010 Time Trials - 5/22/10");
    GatherFromFile("Results20100605_Almaden.htm",      "066", "oldmeet","2010 Santa Teresa vs. Almaden - 6/05/10");
    GatherFromFile("Results20100612_Cudas.htm",        "067", "oldmeet","2010 Santa Teresa vs. Creekside - 6/12/10");
    GatherFromFile("Results20100619_Shadowbrook.htm",  "068", "oldmeet","2010 Santa Teresa vs. Shadowbrook - 6/19/10");
    GatherFromFile("Results20100626_Pinehurst.htm",    "069", "oldmeet","2010 Santa Teresa @ Pinehurst - 6/26/10");
    GatherFromFile("Results20100710_CrossGate.htm",    "070", "oldmeet","2010 Santa Teresa vs. Crossgate - 7/10/10");
    GatherFromFile("Results20100717_Champs.htm",       "071", "oldmeet","2010 Cabana League Championships - 7/17/10");

    GatherFromFile("Results20110521_TimeTrials.htm",   "072", "oldmeet","2011 Time Trials - 5/21/11");
    GatherFromFile("Results20110604_Crossgate.htm",    "073", "oldmeet","2011 Santa Teresa vs. Crossgate - 6/04/11");
    GatherFromFile("Results20110611_Almaden.htm",      "074", "oldmeet","2011 Santa Teresa @ Almaden - 6/11/11");
    GatherFromFile("Results20110618_Creekside.htm",    "075", "oldmeet","2011 Santa Teresa vs. Creekside - 6/18/11");
    GatherFromFile("Results20110625_Shadowbrook.htm",  "076", "oldmeet","2011 Santa Teresa @ Shadowbrook - 6/25/11");
    GatherFromFile("Results20110709_Pinehurst.htm",    "077", "oldmeet","2011 Santa Teresa vs. Pinehurst - 7/09/11");
    GatherFromFile("Results20110716_Champs.htm",       "078", "oldmeet","2011 Cabana League Championships - 7/16/11");

    #2012
    GatherFromFile("Results20120519_TimeTrials.htm",   "079", "oldmeet","2012 Time Trials - 5/19/12");
    GatherFromFile("Results20120602_Pinehurst.htm",    "080", "oldmeet","2012 Santa Teresa @ Pinehurst - 6/02/12");
    GatherFromFile("Results20120609_CrossGate.htm",    "081", "oldmeet","2012 Santa Teresa @ Crossgate - 6/09/12");
    GatherFromFile("Results20120616_Almaden.htm",      "082", "oldmeet","2012 Santa Teresa vs. Almaden - 6/16/12");
    GatherFromFile("Results20120623_Creekside.htm",    "083", "oldmeet","2012 Santa Teresa @ Creekside - 6/23/12");
    GatherFromFile("Results20120630_Shadowbrook.htm",  "084", "oldmeet","2012 Santa Teresa vs. Shadowbrook - 6/30/12");
    GatherFromFile("Results20120714_Champs.htm",       "085", "oldmeet","2012 Cabana League Championships - 7/14/12");


    #2013
    GatherFromFile("Results20130518_TimeTrials.htm",   "086", "oldmeet","2013 Time Trials - 5/18/2013");
    GatherFromFile("Results20130601_Shadowbrook.htm",  "087", "oldmeet","2013 Santa Teresa @ Shadowbrook - 6/01/2013");
    GatherFromFile("Results20130608_Pinehurst.htm",    "088", "oldmeet","2013 Santa Teresa vs. Pinehurst - 6/08/2013");
    GatherFromFile("Results20130615_CrossGate.htm",    "089", "oldmeet","2013 Santa Teresa vs. Crossgate - 6/15/2013");
    GatherFromFile("Results20130622_Almaden.htm",      "090", "oldmeet","2013 Santa Teresa @ Almaden - 6/22/2013");
    GatherFromFile("Results20130629_Creekside.htm",    "091", "oldmeet","2013 Santa Teresa @ Creekside - 6/29/2013");
    GatherFromFile("Results20130713_Champs.htm",       "092", "oldmeet","2013 Santa Teresa @ Almaden - 7/13/2013");
}

sub gatherNewResults
{
    #2014
    GatherFromFile("Results20140517_TimeTrials.htm",   "093", "oldmeet","2014 Time Trials - 5/17/2014");
    #GatherFromFile("Resultsxxx.htm",   "094", "newmeet", "2014 Santa Teresa @ Creekside - 5/31/2014");
    GatherFromFile("Results20140607_Shadowbrook.htm",  "095", "oldmeet", "2014 Santa Teresa vs. Shadow Brook - 6/07/2014");
    GatherFromFile("Results20140614_Pinehurst.htm",    "096", "oldmeet", "2014 Santa Teresa @ Pinehurst - 6/14/2014");
    GatherFromFile("Results20140621_CrossGate.htm",    "097", "oldmeet", "2014 Santa Teresa @ Crossgate - 6/21/2014");
    GatherFromFile("Results20140628_Almaden.htm",      "098", "oldmeet", "2014 Santa Teresa vs. Almaden - 6/28/2014");
    GatherFromFile("Results20140712_Champs.htm",       "099", "oldmeet", "2014 Cabana League Championships - 7/12/2014");


    #2015
    GatherFromFile("Results20150517_TimeTrials.htm",   "100", "newmeet", "2015 Time Trials - 5/17/2015");
    GatherFromFile("Results20150530_Almaden.htm",      "101", "newmeet", "2015 Santa Teresa at Almaden - 5/30/2015");
    GatherFromFile("Results20150606_Creekside.htm",    "102", "newmeet", "2015 Santa Teresa vs. Creekside - 6/06/2015");
    GatherFromFile("Results20150613_Shadowbrook.htm",  "103", "newmeet", "2015 SantaTeresa @ ShadowBrook 6/13/2015");

    GatherFromFile("Results20150620_Pinehurst.htm",    "104", "newmeet", "2015 Santa Teresa vs. Pinehurst - 6/20/2015");
    GatherFromFile("Results20150627_Crossgates.htm",   "105", "newmeet", "2015 Santa Teresa vs. Crossgates - 6/27/2015");
    GatherFromFile("Results20150711_Champs.htm",       "106", "lastmeet", "2015 Cabana League Championships - 7/11/2015");
}

gatherEarlyResults();
gatherMidResults();
gatherNewResults();


#print "\n=======\n";
#foreach $key (sort keys %mapKeyPlace)
#{
#    print "$key \n";
#}
print "\n=======ALIASES==========\n";
foreach $name (sort keys %mapNameKey)
{
    $swimmerNo++;
    if (!defined($aliasMap{$name}))
    {
        if ($name =~ /^(\w)[\w ]*, (\w*)$/)
        {
            $newalias = "$2$1";
            while (defined($aliasReverseMap{$newalias}))
            {
                print "Alias Conflict: $newalias already defined, trying another\n";
                $newalias = "$newalias$swimmerNo";
            }
        }
        else
        {
            $newalias = sprintf("Swimmer%3.3d", $swimmerNo);
        }
        $aliasMap{$name} = $newalias;
        $aliasReverseMap{$newalias} = $name;
    }
    print "$name|$aliasMap{$name}\n";
    $mapNameNumber{$name} = $swimmerNo;
}
print "\n=======CURRENT ALIASES==========\n";
@aliasReverseList;
foreach $name (sort keys %mapSwam2004)
{
    printf("%-24s --> %-16s   ______________\n", $name,  $aliasMap{$name});
    push(@aliasReverseList,"$aliasMap{$name}|$name");
}
print "\n=======REVERSE ALIASES==========\n";
foreach $linex (sort @aliasReverseList)
{
    print "$linex\n";
}
print "\n=======GENERATE PAGES==========\n";
if (1==1) {
    foreach $name (sort keys %mapNameKey)
    {
        CreateSwimmerPage($mapNameNumber{$name}, $name);
    }
}
dumpAllMapMeetKeys();

sub createNewMeets 
{
    #2015
    CreateMeetPage("100");
    CreateMeetPage("101");
    CreateMeetPage("102");
    CreateMeetPage("103");
    CreateMeetPage("104");
    CreateMeetPage("105");
    CreateMeetPage("106");

    #CreateFakePage("104", "2015 Santa Teresa vs. Pinehurst - 6/20/2014");
    #CreateFakePage("105", "2015 2015 Santa Teresa vs. Crossgates - 6/27/2014");
    #CreateFakePage("106", "2015 Champs");

    #2014
    CreateMeetPage("093");
    CreateFakePage("094", "2014 Santa Teresa @ Creekside - 5/31/2014");
    CreateMeetPage("095");
    CreateMeetPage("096");
    CreateMeetPage("097");
    CreateMeetPage("098");
    CreateMeetPage("099");
}

sub earlyMeets
{
    #OLDER MEETS
    CreateMeetPage("001");
    CreateMeetPage("002");
    CreateMeetPage("003");
    CreateMeetPage("004");
    CreateMeetPage("005");
    CreateMeetPage("006");
    CreateMeetPage("007");
    CreateMeetPage("008");
    CreateMeetPage("009");
    CreateMeetPage("010");
    CreateMeetPage("011");
    CreateMeetPage("012");
    CreateMeetPage("013");
    CreateMeetPage("014");
    CreateMeetPage("015");
    CreateMeetPage("016");
    CreateMeetPage("017");
    CreateMeetPage("018");
    CreateMeetPage("019");
    CreateMeetPage("020");
    CreateMeetPage("021");
    CreateMeetPage("022");
    CreateMeetPage("023");
    CreateMeetPage("024");
    CreateMeetPage("025");
    CreateMeetPage("026");
    CreateMeetPage("027");
    CreateMeetPage("028");
    CreateMeetPage("029");
    #CreateMeetPage("030");
    CreateMeetPage("031");
    CreateMeetPage("032");
    CreateMeetPage("033");
    CreateMeetPage("034");
    CreateMeetPage("035");
    CreateMeetPage("036");
    CreateMeetPage("037");
    CreateMeetPage("038");
    CreateMeetPage("039");
    CreateMeetPage("040");
    CreateMeetPage("041");
    CreateMeetPage("042");
    CreateMeetPage("043");
    CreateMeetPage("044");
    CreateMeetPage("045");
    CreateMeetPage("046");
    CreateMeetPage("047");
    CreateMeetPage("048");
    CreateMeetPage("049");
    CreateMeetPage("050");

    CreateMeetPage("051");
    CreateMeetPage("052");
    CreateMeetPage("053");
    CreateMeetPage("054");
    CreateMeetPage("055");
    CreateMeetPage("056");
    CreateMeetPage("057");

    CreateMeetPage("058");
    CreateMeetPage("059");
    CreateMeetPage("060");
    CreateMeetPage("061");
    CreateMeetPage("062");
    CreateMeetPage("063");
    CreateMeetPage("064");
}

sub meets2010to2013
{
    #2010 meets
    CreateMeetPage("065");
    CreateMeetPage("066");
    CreateMeetPage("067");
    CreateMeetPage("068");
    CreateMeetPage("069");
    CreateMeetPage("070");
    CreateMeetPage("071");

    #2011
    CreateMeetPage("072");
    CreateMeetPage("073");
    CreateMeetPage("074");
    CreateMeetPage("075");
    CreateMeetPage("076");
    CreateMeetPage("077");
    CreateMeetPage("078");

    #2012
    CreateMeetPage("079");
    CreateMeetPage("080");
    CreateMeetPage("081");
    CreateMeetPage("082");
    CreateMeetPage("083");
    CreateMeetPage("084");
    CreateMeetPage("085");

    #2013
    CreateMeetPage("086");
    CreateMeetPage("087");
    CreateMeetPage("088");
    CreateMeetPage("089");
    CreateMeetPage("090");
    CreateMeetPage("091");
    CreateMeetPage("092");
}

earlyMeets();
meets2010to2013();
createNewMeets();
CreateAlphaPage();

print "--- RUN END ---\n";
