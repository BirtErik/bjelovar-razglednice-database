create or replace NONEDITIONABLE PACKAGE BODY ROUTER AS

  procedure p_main(p_in IN CLOB, p_out OUT CLOB) AS
    l_obj JSON_OBJECT_T;
    l_procedura varchar2(40);
    l_string      CLOB;
  BEGIN
    l_obj := json_object_t(p_in);
    l_string := l_obj.to_clob;
    

    SELECT
        JSON_VALUE(p_in, '$.procedura' RETURNING VARCHAR2)
    INTO
        l_procedura
    FROM DUAL;

    CASE l_procedura
    WHEN 'p_zupanije' THEN
        dohvat.p_get_zupanije(JSON_OBJECT_T(p_in), l_obj);
    WHEN 'p_login' THEN
        dohvat.p_login(JSON_OBJECT_T(p_in), l_obj);
    WHEN 'p_klijenti' THEN
        dohvat.p_get_klijenti(JSON_OBJECT_T(p_in), l_obj); 
    WHEN 'p_media' THEN
        dohvat.p_get_media(JSON_OBJECT_T(p_in), l_obj);
    WHEN 'p_lokacije' THEN
        dohvat.p_get_lokacije(JSON_OBJECT_T(p_in), l_obj);
    WHEN 'p_aplikacije' THEN 
        dohvat.p_get_aplikacije(JSON_OBJECT_T(p_in), l_obj);
    WHEN 'p_save_korisnici' THEN
       save.p_save_korisnici(JSON_OBJECT_T(p_in), l_obj); 
    WHEN 'p_save_data' THEN
        save.p_save_data(p_in, l_obj);
    ELSE
        l_obj.put('h_message', ' Nepoznata metoda ' || l_procedura);
        l_obj.put('h_errcode', 997);
    END CASE;
    p_out := l_obj.TO_STRING;
  END p_main;
END ROUTER;
