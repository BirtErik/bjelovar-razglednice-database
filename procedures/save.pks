create or replace NONEDITIONABLE PACKAGE SAVE AS 

  procedure p_save_korisnici(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T);
  procedure p_save_data(in_json in clob, out_json out JSON_OBJECT_T);
  
END SAVE;
