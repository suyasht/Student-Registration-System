----PROJECT SPECIFICATION


Create or replace package Project_core_package
is
type data_cursor is ref cursor;
procedure show_students(s_cursor OUT data_cursor );
procedure show_courses(cou_cursor OUT data_cursor);
procedure show_prerequisites(prere_cursor OUT data_cursor);
procedure show_classes(cla_cursor OUT data_cursor);
procedure show_enrollments(enrol_cursor OUT data_cursor);
procedure show_logs(logs_cursor OUT data_cursor);
procedure add_students(sid_t IN students.sid%type, firstname_t IN students.firstname%type,
                        lastname_t IN students.lastname%type, status_t IN students.status%type,
                        gpa_t IN students.gpa%type, email_t IN students.email%type,
                        msg OUT varchar);


procedure class_information(classid_n IN classes.classid%type,
			message OUT varchar2,cl_cursor OUT data_cursor
			,stu_cursor OUT data_cursor);

PROCEDURE show_prereq(prerequisites_dept_code in prerequisites.dept_code%type,
		     prerequisites_course_number in prerequisites.course_no%type,
		     Message out varchar);

PROCEDURE Students_information(student_id in students.sid%type,
				Message OUT varchar,
				Student_cursor OUT data_cursor);
procedure enroll_a_student_into_a_class(classes_classid in classes.classid%type,
					student_sid in students.sid%type,
					message out varchar);
procedure delete_student(sidn in students.sid%type,out_message out varchar);

end Project_core_package;
/


-----PROJECT BODY EXECUTION

--Q2


create or replace package body Project_core_package as
procedure show_students(s_cursor OUT data_cursor )
is
begin
open s_cursor for select * from students;
end show_students;


procedure show_courses(cou_cursor OUT data_cursor)
is
begin
open cou_cursor for select * from courses;
end show_courses;


procedure show_prerequisites(prere_cursor OUT data_cursor)
is
begin
open prere_cursor for select * from prerequisites;
end show_prerequisites;


procedure show_classes(cla_cursor OUT data_cursor)
is
begin
open cla_cursor for select * from classes;
end show_classes;


procedure show_enrollments(enrol_cursor OUT data_cursor)
is
begin
open enrol_cursor for select * from enrollments;
end show_enrollments;


procedure show_logs(logs_cursor OUT data_cursor)
is
begin
open logs_cursor for select * from logs;
end show_logs;



--Q3


procedure add_students(sid_t IN students.sid%type, firstname_t IN students.firstname%type,
                        lastname_t IN students.lastname%type, status_t IN students.status%type,
                        gpa_t IN students.gpa%type, email_t IN students.email%type,
                        msg OUT varchar)
is
begin
insert into students values(sid_t ,firstname_t,lastname_t,status_t,gpa_t,email_t);
COMMIT;
msg := 'success';

EXCEPTION
WHEN OTHERS THEN
msg := 'error';
end add_students;



-- Q4


procedure Students_information(student_id IN students.sid%type,Message OUT varchar ,Student_cursor OUT data_cursor)
is
sc number(2);
se number(2);
begin
select count(sid) into sc from students where sid = student_id;
select count(sid) into se from enrollments where sid = student_id;

if sc = 0 then	
Message := 'The sid is invalid';
elsif se = 0 then	
Message := 'The student has not taken any course';
else
open Student_cursor for
select distinct st.sid,st.lastname,st.status,cl.classid,cl.dept_code||cl.course_no as course,co.title,cl.year,cl.semester from students st,courses co,classes cl,enrollments en
where en.sid = st.sid and cl.dept_code || cl.course_no = co.dept_code || co.course_no and en.classid = cl.classid and st.sid = student_id;
Message := 'success';
end if;
end Students_information;



--Q5


PROCEDURE show_prereq(
prerequisites_dept_code in prerequisites.dept_code%type,
prerequisites_course_number in prerequisites.course_no%type,
Message out varchar)
as
department_code varchar2(4);
course_number number(3);
temp_message varchar(5000);
cursor prerequisite_cursor is

(select pre_dept_code, pre_course_no from prerequisites 
where prerequisites.course_no = prerequisites_course_number and prerequisites.dept_code = prerequisites_dept_code );
prerequisite_cursor_row prerequisite_cursor%rowtype;
cursor course_cursor is
(select dept_code, course_no, title from courses where courses.course_no = prerequisites_course_number and courses.dept_code = prerequisites_dept_code);
course_cursor_row course_cursor%rowtype;
BEGIN
open course_cursor;
fetch course_cursor into course_cursor_row;
if (course_cursor%notfound) then 
Message := 'Entered course not found.';
else
open prerequisite_cursor;    
fetch prerequisite_cursor into prerequisite_cursor_row;    
while prerequisite_cursor%found loop
department_code := prerequisite_cursor_row.pre_dept_code;
course_number := prerequisite_cursor_row.pre_course_no;
if (prerequisite_cursor_row.pre_dept_code IS NOT NULL) then
if (Message IS not NULL) THEN
Message := Message ||' '|| department_code || course_number;
end if;
if (Message IS NULL) THEN
Message := department_code || course_number;
end if;
show_prereq(department_code, course_number, temp_message);
if (temp_message IS not NULL) THEN
Message := Message ||' '|| temp_message;
end if;
else
return;
end if;
fetch prerequisite_cursor into prerequisite_cursor_row;
end loop;            
end if;         
END show_prereq;

--Q6

procedure class_information(classid_n IN classes.classid%type,message OUT varchar2,cl_cursor OUT data_cursor,stu_cursor OUT data_cursor)
as
cid_check number(2);
cl_check number(2);
begin
select count(classid) into cid_check from classes where classid = classid_n;
select count(sid) into cl_check from enrollments where classid = classid_n;

if cid_check = 0 then	-- check if course exists
message := 'The classid is invalid';
elsif cl_check = 0 then	-- check if student enrolled in class
message := 'No student is enrolled in the class';
else
open cl_cursor for 
select cl.classid,co.title,cl.semester,cl.year from classes cl,courses co where cl.dept_code || cl.course_no = co.dept_code || co.course_no and cl.classid = classid_n;

open stu_cursor for
select st.sid,st.lastname from students st,enrollments en where en.classid = classid_n and st.sid = en.sid;
message := 'success';
end if;

end class_information;

--Q7


procedure enroll_a_student_into_a_class(
classes_classid in classes.classid%type,
student_sid in students.sid%type,
message out varchar)
IS
cursor students_cursor is
select sid, firstname, lastname,status,gpa, email from students where sid = student_sid;
students_row_cursor students_cursor%rowtype;

cursor classes_cursor is
select classid, dept_code, course_no, sect_no, year, semester, limit, class_size from classes where classid = classes_classid;
classes_row_cursor classes_cursor%rowtype;

cursor title_cursor is
select title from courses c1, classes c2 where c1.dept_code = c2.dept_code and c1.course_no = c2.course_no and classid = classes_classid;
title_row_cursor title_cursor%rowtype;

cursor courses_cursor is
select concat(classes.dept_code,classes.course_no) as course from classes where classid = classes_classid;
courses_row_cursor courses_cursor%rowtype;

cursor enrollments_cursor is
select students.sid, students.firstname from students where sid in (select enrollments.sid from enrollments where enrollments.classid = classes_classid);
enrolledstudents_row_cursor enrollments_cursor%rowtype;

cursor courses_taken_cursor is
select concat(classes.dept_code,classes.course_no) as course from classes 
where classes.classid in (select enrollments.classid from enrollments
where enrollments.sid = student_sid and 
enrollments.classid in (select classes.classid from classes where 
(semester, year) in (select semester, year from classes where classid = classes_classid)));
courses_taken_row_cursor courses_taken_cursor%rowtype;

cursor enrollments_count_cursor is
select count(*) as count from enrollments
where enrollments.sid = student_sid and 
classid in (select classes.classid from classes where (semester, year) in (select classes.semester, classes.year from classes where classid = classes_classid));
enrollments_count_row_cursor enrollments_count_cursor%rowtype;

cursor prerequisites_cursor is
(select concat(prerequisites.pre_dept_code,prerequisites.pre_course_no) as course from prerequisites 
where (dept_code, course_no) in (select dept_code, course_no from classes where classid = classes_classid));
prerequisites_row_cursor prerequisites_cursor%rowtype;

cursor prerequisites_completed_cursor is
select concat(classes.dept_code,classes.course_no) as course from classes 
where classes.classid in (select enrollments.classid from enrollments where sid = student_sid and lgrade in ('A','B','C','D'));
prereq_comp_row_cursor prerequisites_completed_cursor%rowtype;

prerequisites_completed_or_not boolean;
begin
prerequisites_completed_or_not := false;
open students_cursor;
fetch students_cursor into students_row_cursor;
if (students_cursor%notfound) then
message := 'The sid is invalid';
else 
open classes_cursor;
fetch classes_cursor into classes_row_cursor;
if (classes_cursor%notfound) then
message := 'The classid is invalid';
else 
if(classes_row_cursor.class_size >= classes_row_cursor.limit) then
message := 'The class is closed';  
else
open courses_cursor;
fetch courses_cursor into courses_row_cursor;
open courses_taken_cursor;
fetch courses_taken_cursor into courses_taken_row_cursor;
while courses_taken_cursor%found loop
if (courses_row_cursor.course = courses_taken_row_cursor.course) then 
message := 'The student is already in the class.';
return;
end if;
fetch courses_taken_cursor into courses_taken_row_cursor;
end loop;
open enrollments_count_cursor;
fetch enrollments_count_cursor into enrollments_count_row_cursor;
if (enrollments_count_cursor%found) then
if (enrollments_count_row_cursor.count = 4) then
message := 'Students cannot be enrolled in more than four classes in the same semester';
return;
end if;
open prerequisites_cursor;
fetch prerequisites_cursor into prerequisites_row_cursor;
open prerequisites_completed_cursor;
while prerequisites_cursor%found loop
fetch prerequisites_completed_cursor into prereq_comp_row_cursor;
while prerequisites_completed_cursor%found loop
if (prereq_comp_row_cursor.course = prerequisites_row_cursor.course) then
prerequisites_completed_or_not := true;
end if;
fetch prerequisites_completed_cursor into prereq_comp_row_cursor;
end loop;
if(not prerequisites_completed_or_not) then
message := 'Prerequisite courses have not been completed';
return;
end if;
prerequisites_completed_or_not := false;
fetch prerequisites_cursor into prerequisites_row_cursor;
end loop;
if(enrollments_count_row_cursor.count < 3) then
INSERT INTO enrollments VALUES (student_sid, classes_classid, null);
message := 'Student enrollment successful. ';
end if;    
if(enrollments_count_row_cursor.count = 2) then
message := message || 'You are overloaded.';
INSERT INTO enrollments VALUES (student_sid, classes_classid, null);
end if;
end if;
end if;
end if;
end if;
end enroll_a_student_into_a_class;



--Q8





--Q9
procedure delete_student(sidn in students.sid%type,out_message out varchar)
is
cursor sid_c is
select * from students where sid = sidn;
 del_stu sid_c%rowtype;
begin

       open sid_c;

fetch sid_c into del_stu;
if (sid_c%notfound) then
    out_message := 'Student not found.';
   else 
       delete from students where sid = sidn;
    out_message := 'Student deleted.';
       
end if;

end delete_student;

end Project_core_package;
/