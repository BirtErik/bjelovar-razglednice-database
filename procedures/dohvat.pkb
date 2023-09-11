create or replace NONEDITIONABLE PACKAGE BODY DOHVAT AS
e_iznimka exception;
------------------------------------------------------------------------------------
--get_zupanije
  procedure p_get_zupanije (in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T) AS
  l_obj JSON_OBJECT_T;
  l_zupanije json_array_t :=JSON_ARRAY_T('[]');
  l_count number;
  l_id number;
  l_string varchar2(1000);
  l_search varchar2(100);
  l_page number; 
  l_perpage number; 
 BEGIN
    l_obj := JSON_OBJECT_T(in_json);

    l_string := in_json.TO_STRING; 

    SELECT
        JSON_VALUE(l_string, '$.ID' ),
        JSON_VALUE(l_string, '$.search'),
        JSON_VALUE(l_string, '$.page' ),
        JSON_VALUE(l_string, '$.perpage' )
    INTO
        l_id,
        l_search,
        l_page,
        l_perpage
    FROM 
       dual;

    FOR x IN (
            SELECT 
               json_object('ID' VALUE ID, 
                           'ZUPANIJA' VALUE ZUPANIJA) as izlaz
             FROM
                common.zupanije
             where
                ID = nvl(l_id, ID) and 
                upper(zupanija) like nvl('%' || upper(l_search) || '%', upper(zupanija)) 
                OFFSET NVL(l_page,0) ROWS FETCH NEXT NVL(l_perpage,1) ROWS ONLY
            )
        LOOP
            l_zupanije.append(JSON_OBJECT_T(x.izlaz));
        END LOOP;

    SELECT
      count(1)
    INTO
       l_count
    FROM 
       common.zupanije;

    l_obj.put('count',l_count);
    l_obj.put('data',l_zupanije);
    out_json := l_obj;

  END p_get_zupanije;

--get_klijenti
------------------------------------------------------------------------------------
  procedure p_get_klijenti(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T) AS
  l_obj JSON_OBJECT_T;
  l_klijenti json_array_t :=JSON_ARRAY_T('[]');
  l_count number;
  l_id number;
  l_string varchar2(1000);
  l_search varchar2(100);
  l_page number; 
  l_perpage number; 
 BEGIN
    l_obj := JSON_OBJECT_T(in_json);

    l_string := in_json.TO_STRING; 

    SELECT
        JSON_VALUE(l_string, '$.ID' ),
        JSON_VALUE(l_string, '$.search'),
        JSON_VALUE(l_string, '$.page' ),
        JSON_VALUE(l_string, '$.perpage' )
    INTO
        l_id,
        l_search,
        l_page,
        l_perpage
    FROM 
       dual;

    FOR x IN (
            SELECT 
               json_object('ID' VALUE ID, 
                           'IME' VALUE IME,
                           'PREZIME' VALUE PREZIME,
                           'EMAIL' VALUE EMAIL,
                           'PASSWORD' VALUE PASSWORD) as izlaz
             FROM
                korisnici
             where
                ID = nvl(l_id, ID) 
            )
        LOOP
            l_klijenti.append(JSON_OBJECT_T(x.izlaz));
        END LOOP;

    SELECT
      count(1)
    INTO
       l_count
    FROM 
       common.korisnici
    where
        ID = nvl(l_id, ID) 
        OFFSET NVL(l_page,0) ROWS FETCH NEXT NVL(l_perpage,1) ROWS ONLY; 
        -- u postman treba stavit sto trazimo i page i perpage. 

    l_obj.put('count',l_count);
    l_obj.put('data',l_klijenti);
    out_json := l_obj;
 EXCEPTION
   WHEN OTHERS THEN
       common.p_errlog('p_get_klijenti', dbms_utility.format_error_backtrace, sqlcode, sqlerrm, l_string);
       l_obj.put('h_message', 'GreÅ¡ka u obradi podataka');
       l_obj.put('h_errcode', 99);
       ROLLBACK;    

  END p_get_klijenti;
------------------------------------------------------------------------------------
--login
 PROCEDURE p_login(in_json in json_object_t, out_json out json_object_t )AS
    l_obj        json_object_t := json_object_t();
    l_input      VARCHAR2(4000);
    l_record     VARCHAR2(4000);
    l_username   korisnici.email%TYPE;
    l_password   korisnici.password%TYPE;
    l_id         korisnici.id%TYPE;
    l_out        json_array_t := json_array_t('[]');
 BEGIN
    l_obj.put('h_message', '');
    --l_obj.put('h_errcode', '');
    l_input := in_json.to_string;
    SELECT
        JSON_VALUE(l_input, '$.username' RETURNING VARCHAR2),
        JSON_VALUE(l_input, '$.password' RETURNING VARCHAR2)
    INTO
        l_username,
        l_password
    FROM
        dual;

    IF (l_username IS NULL OR l_password is NULL) THEN
       l_obj.put('h_message', 'Molimo unesite korisniÄ�ko ime i zaporku');
       l_obj.put('h_errcod', 101);
       RAISE e_iznimka;
    ELSE
       BEGIN
          SELECT
             id
          INTO 
             l_id
          FROM
             korisnici
          WHERE
             email = l_username AND 
             password = l_password;
       EXCEPTION
             WHEN no_data_found THEN
                l_obj.put('h_message', 'Nepoznato korisniÄ�ko ime ili zaporka');
                l_obj.put('h_errcod', 102);
                RAISE e_iznimka;
             WHEN OTHERS THEN
                RAISE;
       END;

       SELECT
          JSON_OBJECT( 
             'ID' VALUE kor.id, 
             'ime' VALUE kor.ime, 
             'prezime' VALUE kor.prezime, 
             'email' VALUE kor.email)
       INTO 
          l_record
       FROM
          korisnici kor
       WHERE
          id = l_id;

    END IF;

    l_out.append(json_object_t(l_record));
    l_obj.put('data', l_out);
    out_json := l_obj;
 EXCEPTION
    WHEN e_iznimka THEN
       out_json := l_obj; 
    WHEN OTHERS THEN
       common.p_errlog('p_users_upd', dbms_utility.format_error_backtrace, sqlcode, sqlerrm, l_input);
       l_obj.put('h_message', 'GreÅ¡ka u obradi podataka');
       l_obj.put('h_errcode', 99);
       ROLLBACK;
 END p_login;
 
--------------------------------------------------------------------------------
--p_get_media
 PROCEDURE p_get_media(in_json in json_object_t, out_json out json_object_t )AS
    l_obj JSON_OBJECT_T;
    l_media json_array_t :=JSON_ARRAY_T('[]');
    l_string varchar2 (5000);
    l_count number;
    l_id number;
    --page i perpage
 BEGIN
        l_obj := JSON_OBJECT_T(in_json);
        l_string := in_json.TO_STRING;
    SELECT
        JSON_VALUE(l_string, '$.ID')

    INTO 
        l_id
    
    FROM
        dual;
 
 FOR x IN (
        SELECT 
            JSON_OBJECT('ID' VALUE ID,
                        'IDAPLIKACIJE' VALUE IDAPLIKACIJE,
                        'IDLOKACIJE' VALUE IDLOKACIJE,
                        'HEADER' VALUE HEADER,
                        'SLIKA' VALUE SLIKA,
                        'VIDEO' VALUE VIDEO,
                        'FOOTER' VALUE FOOTER,
                        'UPDATED' VALUE UPDATED,
                        'CREATED' VALUE CREATED) AS izlaz
        FROM
            media
        WHERE
            ID=nvl(l_id, ID)
        )
        LOOP
            l_media.append(JSON_OBJECT_T(x.izlaz));
        END LOOP; 


/*
-- OUTPUT VALUE TOO LARGE ERROR OD MIDA      
 FOR j IN(
        SELECT
            JSON_OBJECT('ID'  VALUE ID,
                        'LAT' VALUE LAT,
                        'LNG' VALUE LNG) AS izlaz
        FROM
            lokacije
        WHERE
            ID=nvl(l_id, ID)
        )
        LOOP
            l_media.append(JSON_OBJECT_T(j.izlaz));
        END LOOP;
*/      
    SELECT
        count(1)
    INTO
        l_count
    FROM 
        media
    where
        ID = nvl(l_id, ID) ;

    l_obj.put('count',l_count);
    l_obj.put('data',l_media);
    out_json := l_obj;

 EXCEPTION
    WHEN OTHERS THEN
       common.p_errlog('p_get_klijenti', dbms_utility.format_error_backtrace, sqlcode, sqlerrm, l_string);
       l_obj.put('h_message', 'GreÅ¡ka u obradi podataka');
       l_obj.put('h_errcode', 99);
       ROLLBACK;
    
END p_get_media; 
--------------------------------------------------------------------------------
--p_get_lokacije
 PROCEDURE p_get_lokacije(in_json in json_object_t, out_json out json_object_t )AS
    l_obj JSON_OBJECT_T;
    l_lokacije json_array_t :=JSON_ARRAY_T('[]');
    l_string varchar2 (5000);
    l_count number;
    l_id number;
    
 BEGIN
        l_obj := JSON_OBJECT_T(in_json);
        l_string := in_json.TO_STRING;
    SELECT
        JSON_VALUE(l_string, '$.ID')

    INTO 
        l_id
    
    FROM
        dual;
 
 FOR x IN (
        SELECT 
            JSON_OBJECT('ID' VALUE ID,
                        'LAT' VALUE LAT,
                        'LNG' VALUE LNG,
                        'TITLE' VALUE TITLE,
                        'TEKST' VALUE TEKST,
                        'MARKER' VALUE MARKER,
                        'UPDATED' VALUE UPDATED,
                        'CREATED' VALUE CREATED) AS izlaz
        FROM
            lokacije
        WHERE
            ID=nvl(l_id, ID)
        ORDER BY
            ID asc
        )
        LOOP
            l_lokacije.append(JSON_OBJECT_T(x.izlaz));
        END LOOP; 
 
    SELECT
        count(1)
    INTO
        l_count
    FROM 
        lokacije
    where
        ID = nvl(l_id, ID) ;

    l_obj.put('count',l_count);
    l_obj.put('data',l_lokacije);
    out_json := l_obj;

 EXCEPTION
    WHEN OTHERS THEN
       common.p_errlog('p_get_klijenti', dbms_utility.format_error_backtrace, sqlcode, sqlerrm, l_string);
       l_obj.put('h_message', 'GreÅ¡ka u obradi podataka');
       l_obj.put('h_errcode', 99);
       ROLLBACK;
       
END p_get_lokacije;
--------------------------------------------------------------------------------
--p_get_aplikacije
 PROCEDURE p_get_aplikacije(in_json in json_object_t, out_json out json_object_t)AS
    l_obj JSON_OBJECT_T;
    l_aplikacije json_array_t :=JSON_ARRAY_T('[]');
    l_string varchar2 (5000);
    l_count number;
    l_id number;
    
 BEGIN
        l_obj := JSON_OBJECT_T(in_json);
        l_string := in_json.TO_STRING;
    SELECT
        JSON_VALUE(l_string, '$.ID')

    INTO 
        l_id
    
    FROM
        dual;
 
 FOR x IN (
        SELECT 
            JSON_OBJECT('ID' VALUE ID,
                        'IME' VALUE IME,
                        'UPDATED' VALUE UPDATED,
                        'CREATED' VALUE CREATED) AS izlaz
        FROM
            aplikacije
        WHERE
            ID=nvl(l_id, ID)
        )
        LOOP
            l_aplikacije.append(JSON_OBJECT_T(x.izlaz));
        END LOOP; 
        
    SELECT
        count(1)
    INTO
        l_count
    FROM 
        aplikacije
    where
        ID = nvl(l_id, ID) ;

    l_obj.put('count',l_count);
    l_obj.put('data',l_aplikacije);
    out_json := l_obj;

 EXCEPTION
    WHEN OTHERS THEN
       common.p_errlog('p_get_klijenti', dbms_utility.format_error_backtrace, sqlcode, sqlerrm, l_string);
       l_obj.put('h_message', 'GreÅ¡ka u obradi podataka');
       l_obj.put('h_errcode', 99);
       ROLLBACK;
       
END p_get_aplikacije;



END DOHVAT;
