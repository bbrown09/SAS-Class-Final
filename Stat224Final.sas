*Final Project 224;

*Report 1;
*read in our data;
	
DATA final;
	infile "/folders/myshortcuts/Downloads/Final_Data/*.txt" dlm="@";
	length ID $5. Date 3. Course $10.;
	input ID $ Date Course $ Credit Grade $;
	*We need grade to be a number grade in order to calculate GPA;
	*I used the less pretty option of just converting each grade to a number value;
	IF Grade = "A" THEN GPAgrade = 4.0;
	ELSE IF Grade = "A-" THEN GPAgrade = 3.7;
	ELSE IF Grade = "B+" THEN GPAgrade = 3.4;
	ELSE IF Grade = "B" THEN GPAgrade = 3.0;
	ELSE IF Grade = "B-" THEN GPAgrade = 2.7;
	ELSE IF Grade = "C+" THEN GPAgrade = 2.4;
	ELSE IF Grade = "C" THEN GPAgrade = 2.0;
	ELSE IF Grade = "C-" THEN GPAgrade = 1.7;
	ELSE IF Grade = "D+" THEN GPAgrade = 1.4;
	ELSE IF Grade = "D" THEN GPAgrade = 1.0;
	ELSE IF Grade = "D-" THEN GPAgrade = 0.7;
	ELSE GPAgrade = 0;
run;

*CALCULATE A SEMESTER GPA ;
*Don't include P's or other non graded values;
PROC SQL;
	Create table SemesterGPA as
	select ID, Date, round(sum(GPAgrade*Credit)/sum(Credit), .01) as SemGPA,
	sum(GPAgrade*Credit) as N, sum(Credit) as D
	from final
	where Grade not in ("P" "W" "NS" "T")
	group by ID, Date
	;
quit;

*calculate overall gpa;
PROC SQL;
	Create table overallGPA as 
	select ID, round(sum(GPAgrade*Credit)/sum(Credit), .01) as oaGPA
	from final
	where Grade not in ("P" "W" "NS" "T")
	group by ID
	;
quit;

*CALCULATE CREDIT HOURS EARNED;
PROC SQL;
	Create table CHE as
	select ID, Date, sum(Credit) as CredHE
	from final
	where Grade not in ("P" "W" "E" "UW" "I" "IE" "WE" "NS" "T")
	group by ID, Date
	;
quit;

*Calculate Overall Graded Credit Hours;
PROC SQL;
	Create table overallgradedCHE as
	select ID, sum(Credit) as oagradedCredHE
	from final
	where Grade not in ("P" "W" "E" "UW" "I" "IE" "WE" "NS" "T")
	group by ID
	;
quit;

*Calculate Overall Credit Hours including P;
PROC SQL;
	Create table overallCHE as
	select ID, sum(Credit) as oaCredHE
	from final
	where Grade not in ("W" "E" "UW" "I" "IE" "WE" "NS" "T")
	group by ID
	;
quit;

*Calculate cumulative Credit Hours Earned;
Data cumCHE;
	Set CHE;
	By ID;
	if first.ID then cumCredHE=0;
	cumCredHE+CredHE;
run;

*Calculate overall non graded credit hours earned;
PROC SQL;
	Create table notgradedCHE as
	select ID, Date, sum(Credit) as notgradedCredHE
	from final
	where Grade not in ("W" "E" "UW" "I" "IE" "WE" "NS" "T")
	group by ID, Date
	;
quit;

*Calculate non graded cumulative credit hours earned;
Data notgradedcumCHE;
	Set notgradedCHE;
	By ID;
	if first.ID then notgradedcumCredHE=0;
	notgradedcumCredHE+notgradedCredHE;
run;

*In order to calculate cumulative gpa I had to use the math from the semester gpa table;
*I also had to make sure to reset my variables with each new student;
*qualitypoints is a common name for the number of credits taken times the points for the grade.;
Data cumGPA;
	Set semesterGPA;
	by ID Date;
	if first.ID then qualitypoints=0;
	if first.ID then cumCredHE=0;
	if first.ID then cumGPA=0;
	qualitypoints+N;
	cumCredHE+D;
	cumGPA=round(qualitypoints/cumCredHE, .01);
	drop N D semGPA;
run;

*Class Standing Calculator;
PROC SQL;
	Create table classStanding as
	select ID, Date,
	case when cumCredHE<30 then 'Freshman'
	when 30<=cumCredHE<60 then 'Sophomore'
	when 60<=cumCredHE<90 then 'Junior' 
	else 'Senior' end as clStanding
	from cumGPA
	order by ID, Date
	;
quit;

*Sorting my original data to be able to use more efficiently;
proc sort data=final out=finalclasssort;
	by ID course;
run;

*Calculate the number of classes that were repeated while making sure not to count repeatable(R) courses;
Data repeatclass;
	Set finalclasssort;
	by ID course;
	length courseL $ 10.;
	retain courseL;
	if substr(course,length(course),1) = 'R' then delete;
	if course=courseL then numberrepeat=1;
	else numberrepeat=0;
	courseL=course;
	if last.ID then courseL = "NA";
run;

*The official counting step;
data numberRepeatCourses;
	set repeatclass;
	by ID;
	if first.id then repeatcount=0;
	repeatcount+numberrepeat;
run;

*Making a table that shows the total classes that were repeated;
proc sql;
	create table totalrepeatedcourses as
	select ID, course, repeatcount
	from numberRepeatCourses
	where (repeatcount>0)
	order by ID, course, repeatcount
	;
quit;

*organizing the table to just show one ID and how many repeats they had;
data repeatcoursesbystudent;
	set totalrepeatedcourses;
	by ID;
	if not last.ID then delete;
	drop course;
run;

*Calculate total number of grades of each kind students got;
data totalrepeatedgrades;
	set finalclasssort;
	by ID;
	if grade='A' then TotalA+1;
	if grade='A-' then TotalA+1;
	if grade='B+' then TotalB+1;
	if grade='B' then TotalB+1;
	if grade='B-' then TotalB+1;
	if grade='C+' then TotalC+1;
	if grade='C' then TotalC+1;
	if grade='C-' then TotalC+1;
	if grade='D+' then TotalD+1;
	if grade='D' then TotalD+1;
	if grade='D-' then TotalD+1;
	if grade='D+' then TotalD+1;
	if grade='E' then TotalE+1;
	if grade='UW' then TotalE+1;
	if grade='WE' then TotalE+1;
	if grade='IE' then TotalE+1;
	if grade='W' then TotalW+1;
	if first.ID then TotalA=0;
	if first.ID then TotalB=0;
	if first.ID then TotalC=0;
	if first.ID then TotalD=0;
	if first.ID then TotalE=0;
	if first.ID then TotalW=0;
	if not last.ID then delete;
	drop date course credit grade gpagrade;
run;

*Making our final report that will be printed later in the ods html spot;
Data Report1;
	merge semesterGPA cumGPA overallGPA notgradedcumche
	overallche overallgradedche classstanding totalrepeatedcourses totalrepeatedgrades;
	by ID;
	drop N D qualitypoints;
run;

/*test proc report data=report1;
run;*/

*Report 2 GPA of Math/Stat courses;
*Sort data so only Math and Stat classes will show up. Delete everything else;
Data Mathclasssorted;
	set finalclasssort;
	by ID;
	if not find(course, "Math", "i") > 0 then delete;
run;

*Sort data so only Math and Stat classes will show up. Delete everything else;
Data Statclasssorted;
	set finalclasssort;
	by ID;
	if not find(course, "Stat", "i") > 0 then delete;
run;

*combine my math and stat sorts into one table;
Data mathstatcombined;
	merge statclasssorted mathclasssorted;
	by ID;
run;

*Use the same overall GPA calculator from earlier using Math/stat table;
PROC SQL;
	Create table oamathstatGPA as 
	select ID, round(sum(GPAgrade*Credit)/sum(Credit), .01) as oaMSGPA
	from mathstatcombined
	where Grade not in ("P" "W" "NS" "T")
	group by ID
	;
quit;

*Use the same overall graded credit hours calculator from earlier using Math/stat table;
PROC SQL;
	Create table overallMSgradedCHE as
	select ID, sum(Credit) as oaMSgradedCredHE
	from mathstatcombined
	where Grade not in ("P" "W" "E" "UW" "I" "IE" "WE" "NS" "T")
	group by ID
	;
quit;

*Use the same overall credit hour calculator from earlier using Math/stat table;
PROC SQL;
	Create table overallMSCHE as
	select ID, sum(Credit) as MSoacredhe
	from mathstatcombined
	where Grade not in ("W" "E" "UW" "I" "IE" "WE" "NS" "T")
	group by ID
	;
quit;

*Use the same repeat class calculator from earlier using Math/stat table;
Data repeatMSclass;
	Set mathstatcombined;
	by ID course;
	length courseL $ 10.;
	retain courseL;
	if substr(course,length(course),1) = 'R' then delete;
	if course=courseL then numberrepeat=1;
	else numberrepeat=0;
	courseL=course;
	if last.ID then courseL = "NA";
run;

*Use the same repeat class calculator from earlier using Math/stat table;
data numberRepeatMSCourses;
	set repeatMSclass;
	by ID;
	if first.id then msrepeatcount=0;
	msrepeatcount+numberrepeat;
run;

*Use the same repeat class calculator from earlier using Math/stat table;
proc sql;
	create table totalrepeatedMScourses as
	select ID, course, msrepeatcount
	from numberRepeatMSCourses
	where (msrepeatcount>0)
	order by ID, course, msrepeatcount
	;
quit;

*Use the same repeat class calculator from earlier using Math/stat table;
data repeatMScoursesbystudent;
	set totalrepeatedMScourses;
	by ID;
	if not last.ID then delete;
	drop course;
run;

*Use the same total number of grades calculator from earlier using Math/stat table;
data totalrepeatedMSgrades;
	set mathstatcombined;
	by ID;
	if grade='A' then mathTotalA+1;
	if grade='A-' then mathTotalA+1;
	if grade='B+' then mathTotalB+1;
	if grade='B' then mathTotalB+1;
	if grade='B-' then mathTotalB+1;
	if grade='C+' then mathTotalC+1;
	if grade='C' then mathTotalC+1;
	if grade='C-' then mathTotalC+1;
	if grade='D+' then mathTotalD+1;
	if grade='D' then mathTotalD+1;
	if grade='D-' then mathTotalD+1;
	if grade='D+' then mathTotalD+1;
	if grade='E' then mathTotalE+1;
	if grade='UW' then mathTotalE+1;
	if grade='WE' then mathTotalE+1;
	if grade='IE' then mathTotalE+1;
	if grade='W' then mathTotalW+1;
	if first.ID then mathTotalA=0;
	if first.ID then mathTotalB=0;
	if first.ID then mathTotalC=0;
	if first.ID then mathTotalD=0;
	if first.ID then mathTotalE=0;
	if first.ID then mathTotalW=0;
	if not last.ID then delete;
	drop date course credit grade gpagrade;
run;

*Create Report 2 to print later in ods html;
Data Report2;
	merge overallGPA overallCHE overallgradedCHE totalrepeatedcourses
	totalrepeatedgrades oamathstatGPA overallMSCHE overallMSgradedCHE
	repeatMScoursesbystudent totalrepeatedMSgrades;
	by ID;
	drop course;
run;

/*test proc report data=Report2;
run;*/

*Report 3;
/*I wasn't really sure if the instructions wanted me to use more than one macro variable,
but I stuck with it. I ended up using delete because of how many times I use it in the program.*/
%let d=delete;

*create a table that counts total observations;
proc sql;
	create table topGPA as
	select *, count(*) as totalobs
	from report2
	order by oagpa
	;
quit;

*organize the table from the last step so it can be used in future steps;
proc sort data=topGPA out=topGPAsorted;
	by ID oagpa;
run;

*Calculate top ten percent GPA of students between 60 and 130 credits by deleting those
without correct credits and deleting repeat appearances of students.;
Data toppercentGPA;
	set topGPAsorted;
	by ID oagpa;
	if oacredhe<=60 then &d.;
	if oacredhe>=130 then &d.;
	if not last.ID then &d.;
	drop oagradedcredhe repeatcount totalA totalb totalc totald totale totalw;
run;

*Sort data into highest to lowest GPA;
proc sql;
	create table toppercentGPAsorted as
	select ID, oagpa, totalobs, oacredhe
	from toppercentGPA
	order by oagpa desc
	;
quit;

*Count observations on smaller revised table;
proc sql;
	create table topGPAcounter as
	select *, count(*) as tobs
	from toppercentGPAsorted
	order by oagpa desc
	;
quit;

*divide leftover rows by ten to simulate ten percent. Save final result as Report 3;
Data Report3;
	set topGPAcounter;
	if _N_ < round(tobs/10);
	drop totalobs tobs;
run;

*Report 4;
*Repeat steps from report 3 with conditions of greater than 20 math/stat credits;
Data toppercentmsGPA;
	set topGPAsorted;
	by ID oaMSgpa;
	if MSoacredhe<=20 then &d.;
	if not last.ID then &d.;
	drop oagradedcredhe repeatcount totalA totalb totalc totald totale totalw
	oagpa oacredhe oamsgradedcredhe msrepeatcount mathtotalA mathtotalb mathtotalc
	mathtotald mathtotale mathtotalw totalobs;
run;

*Count observations on smaller revised table;
proc sql;
	create table topmsGPAcounter as
	select *, count(*) as toobs
	from toppercentmsGPA
	order by oaMSgpa desc
	;
quit;

*Getting rid of the bottom 90%.
Couldn't round or it cut off one too many observations for some reason.;
*Save as Report 4 since we are done;
Data Report4;
	set topmsGPAcounter;
	if _N_ < (toobs/10);
	drop toobs;
run;

*Report 5;
title "Distribution of Overall GPA of Students";

*I tried the box plot but thought it was boring so I changed to this histogram;
proc sgplot data=report1;
	histogram oagpa / binwidth=.1 showbins;
	yaxis label="Total Number of Students";
	xaxis label="Overall GPA of Student";
run;

title;

/* Here is the box plot code I used and decided against.
proc sgplot data=report1;
	hbox oagpa;
	xaxis label="Overall GPA of Student";
run; */

/* Use ods html to ouput results */
options nodate nonumber;
ods html file="/folders/myfolders/EPG1V2/output/stat224FinalProject.html";
ods noproctitle;
title "Stat 224 Final Project Report";
title;
title "Report 1";
proc report data=report1;
run;

title;

title "Report 2";
proc report data=report2;
run;

title;

title "Report 3";
proc report data=report3;
run;

title;

title "Report 4";
proc report data=report4;
run;

title;

ods html close;