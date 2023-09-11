create or replace NONEDITIONABLE PACKAGE DOHVAT AS 

  procedure p_get_zupanije(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T);
  procedure p_login(in_json in json_object_t, out_json out json_object_t);
  procedure p_get_klijenti(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T);
  procedure p_get_media(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T);
  procedure p_get_lokacije(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T);
  procedure p_get_aplikacije(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T);
  
END DOHVAT;
