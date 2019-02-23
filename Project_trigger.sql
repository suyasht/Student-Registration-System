create or replace trigger LOG_ENTRY_ON_ENROLL_INSERT
AFTER insert on ENROLLMENTS
for each row
begin
insert into logs values (seq_log.nextval, USER, sysdate, 'enrollments', 'insert', :new.sid || ',' || :new.classid);
end;

create or replace trigger INCREASE_CLASS_SIZE
AFTER insert on ENROLLMENTS
for each row
begin
update classes set class_size = class_size + 1 
where classid = :new.classid;
end;

create or replace trigger DECREMENT_CLASS_SIZE
AFTER delete on ENROLLMENTS
for each row
begin
update classes set class_size = class_size - 1 
where classid = :old.classid;
end;

create or replace trigger LOG_ENTRY_ON_STUDENTS_INSERT
AFTER insert on STUDENTS
for each row
begin
insert into logs values (seq_log.nextval, USER, sysdate, 'students', 'insert', :new.sid);
end;

create or replace trigger LOG_ENTRY_ON_ENROLL_DELETE
AFTER delete on ENROLLMENTS
for each row
begin
insert into logs values (seq_log.nextval, USER, sysdate, 'enrollments', 'delete', :old.sid || ',' || :old.classid);
end;

create or replace trigger LOG_ENTRY_ON_STUDENTS_DELETE
AFTER delete on STUDENTS
for each row
begin
insert into logs values(seq_log.nextval, USER, sysdate, 'students', 'delete', :old.sid);
end;

create or replace trigger DECREMENT_ENROLLMENTS
BEFORE delete on STUDENTS
for each row
begin
delete from enrollments where sid = :old.sid;
end;
/