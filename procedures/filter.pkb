create or replace NONEDITIONABLE PACKAGE BODY FILTER AS
e_iznimka exception;

--f_check_korisnik
---------------------------------------------------------------------------------
  function f_check_korisnik(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T) return boolean AS
      l_obj JSON_OBJECT_T;
      l_korisnici korisnici%rowtype;
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
        JSON_VALUE(l_string, '$.IME'),
        JSON_VALUE(l_string, '$.PREZIME' ),
        JSON_VALUE(l_string, '$.EMAIL' ),
        JSON_VALUE(l_string, '$.PASSWORD')
    INTO
        l_korisnici.id,
        l_korisnici.IME,
        l_korisnici.PREZIME,
        l_korisnici.EMAIL,
        l_korisnici.PASSWORD
    FROM 
       dual; 
    
    if (nvl(l_korisnici.IME, ' ') = ' ') then   
       l_obj.put('h_message', 'Molimo unesite ime korisnika'); 
       l_obj.put('h_errcode', 101);
       raise e_iznimka;
    end if;
    
    if (nvl(l_korisnici.PREZIME, ' ') = ' ') then   
       l_obj.put('h_message', 'Molimo unesite prezime korisnika'); 
       l_obj.put('h_errcode', 102);
       raise e_iznimka;
    end if;
    
    if (nvl(l_korisnici.EMAIL, ' ') = ' ') then   
       l_obj.put('h_message', 'Molimo unesite email korisnika'); 
       l_obj.put('h_errcode', 103);
       raise e_iznimka;
    end if;
    
    if (nvl(l_korisnici.id,0) = 0 and nvl(l_korisnici.PASSWORD, ' ') = ' ') then   
       l_obj.put('h_message', 'Molimo unesite zaporku klijenta'); 
       l_obj.put('h_errcode', 108);
       raise e_iznimka;
    end if;
    
    out_json := l_obj;
    return false;
    
  EXCEPTION
     WHEN E_IZNIMKA THEN
        return true;
     WHEN OTHERS THEN
        COMMON.p_errlog('p_check_klijenti',dbms_utility.format_error_backtrace,SQLCODE,SQLERRM, l_string);
        l_obj.put('h_message', 'Dogodila se greÅ¡ka u obradi podataka!'); 
        l_obj.put('h_errcode', 109);
        out_json := l_obj;
        return true;
  END f_check_korisnik;

END FILTER;
