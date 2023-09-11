create or replace NONEDITIONABLE PACKAGE ROUTER AS 
 e_iznimka exception;
    
 procedure p_main(p_in IN CLOB, p_out OUT CLOB);

END ROUTER;
