/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/* fills finished_cloth_d table */

/*
function workdone takes cloth_id scanned by scanner and delete corresponding row from to_do
after adding it in finished_cloth

*/


USE `test2`;
DROP procedure IF EXISTS `work_done`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `work_done`(clothid int)
BEGIN

/*erro handler call rollback if transaction not complete*/
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
     
      ROLLBACK;
END;

START TRANSACTION;

  

    SET @slip := (SELECT slip_id FROM test2.to_do where cloth_id=clothid);
	insert into finished_cloth_d select * from to_do
		where (slip_id,cloth_id)=(@slip,clothid);
        delete from to_do where (slip_id,cloth_id)=(@slip,clothid);

      COMMIT ;

  
END$$

DELIMITER ;

/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/*  fills _order table when student get slip from mobile */

/* 
	Add Trigger on to_do that checks if there are any slip_id in _order not listed in to_do
	if there is any then check whether the time duration exceeds the threshold level,
    if it does exceed then delete that slip_id from _order
 */
 
 /*
	add trigger on to_do that checks whether number of cloths against slip_id excceds
    to that mentioned in _order
 */
 
 /*
	add trigger on to_do that checks that no of cloths on regular basis does not exceed from
    threshold limmit
    
    What if a student gave 15 in total_cloth in _order but realized that he can not pay for any
    and in regular he can only give 12 cloths :
		then he could give next 5 next time but then problem comes that he will be issued task completed
        message only when 15 cloths corresponding to its slip_id got entere in cloth_finished_d
        
	SOLUTION to this:
		make a procedure that update total_cloths in _order for the slip that show warning
 */


/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

*/
USE `test2`;
DROP procedure IF EXISTS `get_slip`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_slip`(slipid int,totalcloth int, cmsid int)
BEGIN
/*erro handler call rollback if transaction not complete*/
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
     
      ROLLBACK;
END;

  
if exists (select * from student where cms=cmsid) then
#case cmsid
#	when 	cmsid = ANY (select cms_id from student) then
START TRANSACTION;


	insert into test2._order VALUES
		(slipid,totalcloth,cmsid,now());

      COMMIT ;
      #could have used end case
	end if;
END$$

DELIMITER ;


/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* get_slip */

USE `test2`;
DROP procedure IF EXISTS `get_slip`;

DELIMITER $$
USE `test2`$$
/*  
  get_slip is used to issue a slip against which cloths could be scheduled,
  
  if a student with cms not in student record gain entry scheduling page of gui due to gui bug
  then this exception is also handled in this function,
  
  this function won't allow students with cms_id not registered in laundry database
  will not be able to receive any slip,
  
  so even if they get entry into scheduling page there cloth will not be scheduled,
  
  WHAT IS THE VALUE OF THIS PROCEDURE AS STUDENT NOT REGISTERED WILL NOT BE ABLE TO SCHEDULE CLOTH
  AS THEIR CLOTHS ARE NOT IN DATABASE ???
  
  ANS :   IF a student has not paid hostel fee or he/she has not paid fee for last paid order then
  its cloths still exists in database but he/she will not be able to issue new schedule for cloths
  
  */
CREATE PROCEDURE `get_slip` (totalcloth int, cmsid int)
BEGIN
/*erro handler call rollback if transaction not complete*/
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
     
      ROLLBACK;
END;

  
if exists (select * from student where cms=cmsid) then
#case cmsid
#	when 	cmsid = ANY (select cms_id from student) then
START TRANSACTION;


	insert into test2._order (total_cloth,cms,_date) VALUES
		(totalcloth,cmsid,now());

      COMMIT ;
      #could have used end case
	end if;
END$$

DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */









/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */


/* first time variable init */
USE `test2`;
DROP procedure IF EXISTS `first_time_init_var`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `first_time_init_var`()
BEGIN
insert into env_variable(regular_cloth_limmit,total_reg_cloth) value (0,0);
END$$

DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */


/*  SET REGULAR CLOTH LIMMIT */
USE `test2`;
DROP procedure IF EXISTS `set_reg_cloth_limmit`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `set_reg_cloth_limmit`(limmit int)
BEGIN

    update env_variable 
    set reg_cloth_limmit = limmit
    where access_flag=1;


END$$

DELIMITER ;

/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */


/* get_reg_cloth_limmit */
USE `test2`;
DROP procedure IF EXISTS `get_reg_cloth_limmit`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_reg_cloth_limmit`()
BEGIN
select regular_cloth_limmit from en_variable ;
END$$

DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/* get total regular cloth   */


USE `test2`;
DROP procedure IF EXISTS `get_total_regular_cloth`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_total_regular_cloth`(slipid int)
BEGIN
 select (select count(order_type_id) from to_do  where (order_type_id=
(select order_type_id from o_type where order_type='regular')
 and slip_id=new.slip_id) group by slip_id)+1;
END$$

DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/* SET total reg cloth by slip id */

USE `test2`;
DROP procedure IF EXISTS `test2`.`set_total_regular_cloth`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `set_total_regular_cloth_Byslipid`(slipid int)
BEGIN
  
  /* takes slip id, get no of regular cloths agaisnt that slip id and set it in its table */
  
  set @total =  (select count(order_type_id) from to_do  where (order_type_id=
  (select order_type_id from o_type where order_type='regular')
  and slip_id=slipid) group by slip_id)+1;
  
    update env_variable 
    set total_reg_cloth = @total
    where access_flag=1;

END$$

DELIMITER ;
;

/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */




/*  SCHEDULE CLOTH  */ 


USE `test2`;
DROP procedure IF EXISTS `schedule_cloth`;

DELIMITER $$
USE `test2`$$
CREATE PROCEDURE `schedule_cloth` (slipid int,clothid int,tasktypeid int,ordertypeid int)
BEGIN
	CASE
		when (not exists(select * from _order where slip_id=slipid)) then
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid slip id';
        
        when (not exists(select * from t_type where task_type_id=tasktypeid)) then
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid task type';
        
        when (not exists(select * from o_type where order_type_id=tasktypeid)) then
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid order type'; 
        
        ELSE Insert into to_do Values
         (slipid,clothid,tasktypeid,ordertypeid,(select cms from _order where slip_id=slipid));
        
    END CASE;
    

END$$

DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */


/*  receive_cloth  */

USE `test2`;
DROP procedure IF EXISTS `receive_cloth`;

DELIMITER $$
USE `test2`$$
CREATE PROCEDURE `receive_cloth` (clothid int)

/* 
	cloth_taken
	
    whenever cloth is taken table of cloth_taken is filled for cloth taken 
    delete that cloth entry from finished_cloth_d
    
 */

BEGIN
/*erro handler call rollback if transaction not complete*/
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
     
      ROLLBACK;
END;

START TRANSACTION;
/* u wont try to access slip_id from to_do when it is not there */
if (select slip_id from to_do where cloth_id = clothid) then
set @slipid = (select slip_id from to_do where cloth_id = clothid);
end if;

if(select slip_id from finished_cloth_d where cloth_id = clothid) then
set @slipid = (select slip_id from finished_cloth_d where cloth_id = clothid);
end if;
set @totalclothtaken = (select total_cloth_taken from cloth_taken where slip_id=@slipid);

/* delete that cloth entry from finished_cloth_d*/
delete from finished_cloth_d where (slip_id,cloth_id)=(@slipid,clothid);
CASE
	when (not exists(select * from cloth_taken where slip_id=@slipid)) then
		insert into cloth_taken values (@slipid,1);
		ELSE update cloth_id set total_cloth = (@totalclothtaken+1) where slip_id=@slipid;

END CASE;
 COMMIT ;
END$$

DELIMITER ;

/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */


/*receive cloth working but dont delete to_do*/
USE `test2`;
DROP procedure IF EXISTS `receive_cloth`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `receive_cloth`(clothid int)
BEGIN
/*erro handler call rollback if transaction not complete*/
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
     
      ROLLBACK;
END;

START TRANSACTION;


if(select slip_id from finished_cloth_d where cloth_id = clothid) then
set @slipid = (select slip_id from finished_cloth_d where cloth_id = clothid);
end if;
set @totalclothtaken = ((SELECT 
            total_cloth_taken
        FROM
            cloth_taken
        WHERE
            slip_id = (SELECT 
                    slip_id
                FROM
                    finished_cloth_d
                WHERE
                    cloth_id = clothid)))+1;
/* delete that cloth entry from finished_cloth_d*/
delete from to_do where (slip_id,cloth_id)=(@slipid,clothid);
CASE
	when (not exists(select * from cloth_taken where slip_id=@slipid)) then
		insert into cloth_taken values (@slipid,1);
		ELSE UPDATE cloth_taken 
SET 
    total_cloth_taken = @totalclothtaken
      
             where slip_id=(SELECT 
                    slip_id
                FROM
                    finished_cloth_d
                WHERE
                    cloth_id = clothid);
END CASE;
 COMMIT ;
END$$

DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/* ADD CHARGING_FEE */

USE `test2`;
DROP procedure IF EXISTS `add_charging_fee`;

DELIMITER $$
USE `test2`$$
CREATE PROCEDURE `add_charging_fee` (clothdescription varchar(15),ironfee int,drycleanfee int,washingfee int)
BEGIN
insert into fee (cloth_type_description,f_iron,f_dry_clean,f_washing) values (clothdescription,ironfee,drycleanfee,washingfee);
END$$

DELIMITER ;

/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

