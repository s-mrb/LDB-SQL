/*TRIGGERS*/

/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/*
	If a slip has been issued and no cloth has been scheduled against that slip_id
    then after 7 days automatically delete that slip_id from _order table 
    so that the number could be re used again

*/

DROP TRIGGER IF EXISTS `test2`.`delete_unused_slip_id_from_order`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER = CURRENT_USER TRIGGER `test2`.`delete_unused_slip_id_from_order` AFTER INSERT ON `to_do` FOR EACH ROW
BEGIN

SET @slipid = (
Select ord.slip_id
FROM _order ord
	LEFT JOIN to_do td On td.slip_id=ord.slip_id
    WHERE td.slip_id is NULL LIMIT 1
    );
    
    /* We could use @slipid in below if
    but it could cause problem in case our query did not gave output
    (i just dont know what will be stored in variable if query dont give desired result) */
if exists (Select ord.slip_id
FROM _order ord
	LEFT JOIN to_do td On td.slip_id=ord.slip_id
    WHERE td.slip_id is NULL LIMIT 1
    ) then
    
    if ((select datediff((select now()),(select _date from _order where slip_id=@slipid))) > 7) then
    delete from _order where slip_id=@slipid;
    end if;
    end if;
END$$
DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

DROP TRIGGER IF EXISTS `test2`.`to_do_BEFORE_INSERT`;

/*

	CHECKS :
				1)  A student has placed 6 cloths on regular(free) basis and is putting 
                next cloth too on regular basis then alert should be given about exceeding threshold limmit

				2)  A student is scheduling cloths more than he/she has taken the ticket/slip_id for

				3)  CMS not registered

				4) Cloth_id verification
                5) invalid task_type check
                6) invalid order_type
                7) invalid slip_id
                
*/

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` TRIGGER `to_do_BEFORE_INSERT` BEFORE INSERT ON `to_do` FOR EACH ROW BEGIN

	/* was not able to use set in case so made a function that update variable value
    and then i can use that variable value in my trigger */
    
	call set_total_regular_cloth_Byslipid(new.slip_id);
CASE	

/* if total cloths scheduled against a cms for regular basis exceeds the threshold */
	WHEN (
		(select total_reg_cloth from env_variable 
				where access_flag=1 )   >   
					(select regular_cloth_limmit from env_variable where access_flag=1)
                    ) then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'limmit exceeded';
      
/* If invalid cms somehow get to the schedula task page it will not be able to proceed */      
	WHEN (not exists (select * from student where cms=new.cms) )then 
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'cms not registered in laundry management system';
      
/* if somehow due to app bug cloth id get changed or someone try to inject fake cloth id or modify a cloth id
then this cloth_id will not be processed */      
	WHEN (not exists (select * from cloth where cloth_id=new.cloth_id)) then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'cloth_id dont exists';
      
/* if someone has not used function to enter data and got passed through exception handlingthere 
then it could be handled here for faulty task_type */
	WHEN (not exists (select * from t_type where task_type_id=new.task_type_id)) then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid Task Type';
      
/* invalid order_type */
	When (not exists (select * from o_type where order_type_id=new.order_type_id)) then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid Order Type';
      
/*  INVALID slip_id check */
	When (not exists (select * from _order where slip_id-new.slip_id)) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Slip ID is invalid';
      
/*  total cloths for slip_id should not exceed from that in _order table */
WHEN (
(select count(cloth_id) from to_do  where  slip_id=new.slip_id group by slip_id)>(select total_cloth from _order where slip_id=new.slip_id)
)
		 then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'limmit exceeded';

 ELSE BEGIN END;     
END CASE;

END$$
DELIMITER ;



/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/*  to automate the process this trigger checks whether for a particular students particular slip_id order is completed yet or not
if it is completed than  sned student the mesage (logic for message not implemented)*/

/* check_for_finished_order */
/*  and delete from _order if condition fills  */

DROP TRIGGER IF EXISTS `test2`.`check_for_finished_order`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER = CURRENT_USER TRIGGER `test2`.`finished_cloth_d_AFTER_INSERT` AFTER INSERT ON `finished_cloth_d` FOR EACH ROW
BEGIN



	if ((
(select count(cloth_id) from to_do  where  slip_id=new.slip_id group by slip_id)=(select total_cloth from _order where slip_id=new.slip_id)
))  then
set @totalcloth = (select total_cloth from _order where slip_id=new.slip_id);
INSERT INTO finished_orders values
	(new.slip_id,new.cms,total_cloth,now());
    
    /*
    You should not delete slip_id yet, if u do then there will be same slip_id one in _order and one in finished_orders
    and that slip_id could consequently move upto finished_cloth_d at the time when completed order for that slip_id is not taken yet
    and that new slip_id will cause hard to debug bug when it tries to go into completed_order
    
DELETE FROM _order 
WHERE
    slip_id = new.slip_id;
*/
end if;






END$$
DELIMITER ;

/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */


/* Finished_cloth before insert */
/*
CHECKS :
		cms not registered
        cloth_id donot exist
        Invalid Task type
        Invalid order type
        Invalid slip_id
*/

DROP TRIGGER IF EXISTS `test2`.`finished_cloth_d_BEFORE_INSERT`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER = CURRENT_USER TRIGGER `test2`.`finished_cloth_d_BEFORE_INSERT` BEFORE INSERT ON `finished_cloth_d` FOR EACH ROW
BEGIN

CASE	

      
/* If invalid cms somehow get to the finished_cloth_ area  it will not be able to proceed */      
	WHEN (not exists (select * from student where cms=new.cms) )then 
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'cms not registered in laundry management system';
      
/* if somehow due to app bug cloth id get changed or someone try to inject fake cloth id or modify a cloth id
then this cloth_id will not be processed */      
	WHEN (not exists (select * from cloth where cloth_id=new.cloth_id)) then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'cloth_id dont exists';
      
/* if someone has not used function to enter data and got passed through exception handlingthere 
then it could be handled here for faulty task_type */
	WHEN (not exists (select * from t_type where task_type_id=new.task_type_id)) then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid Task Type';
      
/* invalid order_type */
	When (not exists (select * from o_type where order_type_id=new.order_type_id)) then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid Order Type';
      
/*  INVALID slip_id check */
	When (not exists (select * from _order where slip_id-new.slip_id)) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Slip ID is invalid';
      
/*  if someone somehow bypassed limmit test on to_do then it could be detected here 
and will be fined appropriately (logic for increased price for this case is not implemented yet) */
WHEN (
(select count(cloth_id) from to_do  where  slip_id=new.slip_id group by slip_id)>(select total_cloth from _order where slip_id=new.slip_id)
)
		 then
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'limmit exceeded';

ELSE BEGIN END;
END CASE;

END$$
DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */


/* 

  each time cloth_taken is inserted or updated check whether total_cloth_taken equal to
 total_cloth in _order
 NEW EXCEPTION : 
				What if by then that order dont exists in _order and new order of same cms 
                and slip issued
     SO DO NOT DELETE record from _order when filling it in finished_orders
     
     
   each time cloth_taken is inserted or updated check whether total_cloth_taken equal to
 total_cloth in _order
 if it is then delete that slip_id record from _order as well as from finished_order
 
 */

DROP TRIGGER IF EXISTS `test2`.`total_receive_check`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER = CURRENT_USER TRIGGER `test2`.`total_receive_check` AFTER INSERT ON `cloth_taken` FOR EACH ROW



BEGIN

if (new.total_cloth_taken = (select total_cloth from _order where slip_id=new.slip_id)) then
	delete from _order where slip_id = new.slip_id;
    delete from finished_order where slip_id = new.slip_id;
    set @slipid = new.slip_id;
    
    /* this slip_id will be given to another */
    /*select @slipid;*/
    
    delete from cloth_taken where slip_id=@slipid;
end if;


END$$
DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/* CHECK CMS AND TOTAL_CLOTH BEFORE INSERTING INTO _order */


/*
	CHECKS: 	
		CMS not registered
        Invalid Total Cloth entry
*/

DROP TRIGGER IF EXISTS `test2`.`check_cms_m_totalcloth`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER = CURRENT_USER TRIGGER `test2`.`check_cms_m_totalcloth` BEFORE INSERT ON `_order` FOR EACH ROW
BEGIN

Case

when (not exists (select * from student where cms=new.cms)) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'CMS not registered in Laundry Management System';

when (new.total_cloth<1) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '0 or negative value for totla_cloth not allowed';
else begin end;
end case;


END$$
DELIMITER ;

/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */



/* Check before inserting in cloth */

/*
	CHECKS :
			CMS not registered
*/

/* same before update */


DROP TRIGGER IF EXISTS `test2`.`check_cms_n_cloth_type_id`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER=`root`@`localhost` TRIGGER `check_cms_n_cloth_type_id` BEFORE INSERT ON `cloth` FOR EACH ROW BEGIN


Case

when (not exists (select * from student where cms=new.cms)) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'CMS not registered in Laundry Management System';

when (not exists (select * from fee where cloth_type_id=new.cloth_type_id)) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No fee structure exists fro this cloth_type_id';


else begin end;
end case;
END$$
DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */


/* student_BEFORE_INSERT */

/* same trigger for update */

/*
	Checks :
			1) for invalid hostel_id
            2) negative cms entered

*/

DROP TRIGGER IF EXISTS `test2`.`student_BEFORE_INSERT`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER = CURRENT_USER TRIGGER `test2`.`student_BEFORE_INSERT` BEFORE INSERT ON `student` FOR EACH ROW
BEGIN

Case

when (not exists (select * from hostel where hostel_id=new.hostel_id)) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid hostel_id';

when (new.cms<0) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Negative cms do not exist';


else begin end;
end case;

END$$
DELIMITER ;


/*  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  */

/* ADMIN adding fee charging criteria for new cloth types
then do not allow entry of cloth type that has already been assigned a charging fee */

/* CLOTH TYPE EXISTS CHECK */
DROP TRIGGER IF EXISTS `test2`.`clothtype_exists_check`;

DELIMITER $$
USE `test2`$$
CREATE DEFINER = CURRENT_USER TRIGGER `test2`.`clothtype_exists_check` BEFORE INSERT ON `fee` FOR EACH ROW
BEGIN
CASE
When (exists (select * from fee where cloth_type_description=new.cloth_type_description)) then
	  SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cloth type already exists';
END CASE;
END$$
DELIMITER ;


