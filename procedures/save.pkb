create or replace NONEDITIONABLE PACKAGE BODY SAVE AS
e_iznimka exception;

  --p_save_korisnici
-----------------------------------------------------------------------------------------
  procedure p_save_korisnici(in_json in JSON_OBJECT_T, out_json out JSON_OBJECT_T) AS
      l_obj JSON_OBJECT_T;
      l_korisnici korisnici%rowtype;
      l_count number;
      l_string varchar2(1000);
      l_search varchar2(100);
      l_page number; 
      l_perpage number;
      l_action varchar2(10);
  begin

     l_obj := JSON_OBJECT_T(in_json);  
     l_string := in_json.TO_STRING;
     

     SELECT
        JSON_VALUE(l_string, '$.ID'),
        JSON_VALUE(l_string, '$.IME'),
        JSON_VALUE(l_string, '$.PREZIME'),
        JSON_VALUE(l_string, '$.EMAIL'),
        JSON_VALUE(l_string, '$.PASSWORD'),
        JSON_VALUE(l_string, '$.ACTION' )
    INTO
        l_korisnici.id,
        l_korisnici.IME,
        l_korisnici.PREZIME,
        l_korisnici.EMAIL,
        l_korisnici.PASSWORD,
        l_action
    FROM 
       dual; 
    
    --FE kontrole
    if (nvl(l_action, ' ') = ' ') then
        if (filter.f_check_korisnik(l_obj, out_json)) then
           raise e_iznimka; 
        end if;  
    end if;
    

    if (l_korisnici.id is null) then
        begin
           insert into korisnici (IME, PREZIME, EMAIL, PASSWORD) values
             (l_korisnici.IME, l_korisnici.PREZIME,
              l_korisnici.EMAIL, l_korisnici.PASSWORD);
           commit;

           l_obj.put('h_message', 'UspjeÅ¡no ste unijeli korisnicia');
           l_obj.put('h_errcode', 0);
           out_json := l_obj;

        exception
           when others then 
              -- COMMON.p_errlog('p_users',dbms_utility.format_error_backtrace,SQLCODE,SQLERRM, l_string);
           l_obj.put('h_message', 'Ne uspijesno ste unijeli korisnicia');
           l_obj.put('h_errcode', 2);
              
               rollback;
               raise;
        end;
    else
       if (nvl(l_action, ' ') = 'delete') then
           begin
               delete korisnici where id = l_korisnici.id;
               commit;    

               l_obj.put('h_message', 'UspjeÅ¡no ste obrisali korisnicia'); 
               l_obj.put('h_errcode', 0);
               out_json := l_obj;
            exception
               when others then 
                   --COMMON.p_errlog('p_users',dbms_utility.format_error_backtrace,SQLCODE,SQLERRM, l_string);
                   rollback;
                   raise;
            end;

       else

           begin
               update korisnici 
                  set IME = l_korisnici.IME,
                      PREZIME = l_korisnici.PREZIME,
                      EMAIL = l_korisnici.EMAIL
               where
                  id = l_korisnici.id;
               commit;    

               l_obj.put('h_message', 'UspjeÅ¡no ste promijenili korisnicia'); 
               l_obj.put('h_errcode', 0);
               out_json := l_obj;
            exception
               when others then 
                   --COMMON.p_errlog('p_korisnici',dbms_utility.format_error_backtrace,SQLCODE,SQLERRM, l_string);
                   rollback;
                   raise;
            end;
       end if;     
    end if;


  exception
     when e_iznimka then
        out_json := l_obj;
     when others then
        --COMMON.p_errlog('p_save_korisnici',dbms_utility.format_error_backtrace,SQLCODE,SQLERRM, l_string);
        l_obj.put('h_message', 'Dogodila se greÅ¡ka u obradi podataka!'); 
        l_obj.put('h_errcode', 101);
        out_json := l_obj;
  END p_save_korisnici;

-------------------------------------------------------------------------------
--P_SAVE_DATA
procedure p_save_data(in_json in clob, out_json out json_object_t) AS 
    l_obj JSON_OBJECT_T;
    l_string varchar2(5000);
    inserted_id lokacije.ID%TYPE;
    l_action varchar2(10);
    l_lokacije lokacije%rowtype;
    l_created number;
    
BEGIN
    l_obj := JSON_OBJECT_T(in_json);
    
    
    select
        JSON_VALUE(in_json, '$.data.id'),
        JSON_VALUE(in_json, '$.data.action'),
        JSON_VALUE(in_json, '$.data.idcreated')
    INTO
        l_lokacije.id,
        l_action,
        l_created
    FROM
        dual;
    
    if (nvl(l_action, ' ') = 'delete') then
        BEGIN
            DELETE MEDIA WHERE IDLOKACIJE = l_lokacije.id;
            DELETE LOKACIJE WHERE ID = l_lokacije.id;
        commit;
            
            l_obj.put('h_message', 'Uspješno ste obrisali korisnika'); 
            l_obj.put('h_errcode', 0);
            out_json := l_obj;
            
        exception
               when others then 
                   --COMMON.p_errlog('p_users',dbms_utility.format_error_backtrace,SQLCODE,SQLERRM, l_string);
                   rollback;
                   raise;
            end;
        END IF;
        
         if (l_lokacije.id is null) then
            begin
                FOR x IN (
                    SELECT
                        title,
                        tekst,
                        lat,
                        lng
                        
                    FROM 
                        JSON_TABLE(in_json, '$.data[*]'
                                COLUMNS(title clob PATH '$.title',
                                        tekst clob PATH '$.tekst',
                                        lat    PATH '$.lokacija.lat',
                                        lng    PATH '$.lokacija.long'
                                    )         
                                )
                            )
        
                    LOOP
                        --IDCREATED PROMIJENIT U L_ID / DODAJ KOD ZA DOHVACANJE L_ID-a
                        IF x.lat is not null and x.lng is not null and x.title is not null and x.tekst is not null THEN
                        INSERT INTO 
                            LOKACIJE (LAT, LNG, TITLE, TEKST, MARKER, IDCREATED)
                
                        VALUES
                            (x.lat, x.lng, x.title, x.tekst, 'https://unpkg.com/leaflet@1.3.4/dist/images/marker-icon.png', l_created) 
                                RETURNING ID INTO inserted_id ;
                
                        commit;
          
                FOR y IN (
                    SELECT
                        header,
                        slika,
                        video,
                        footer
                    FROM
                        JSON_TABLE(in_json, '$.data.o_rezultat[*]' 
                                COLUMNS (header clob PATH '$.header',
                                         slika  clob PATH '$.slika',
                                         video  clob PATH '$.video',
                                         footer clob PATH '$.footer'
                                    )
                                ) --WHERE footer like x.title || '%' OR slika like x.title || '%'
                            )     --ODKOMENTIRAJ SAMO PRILIKOM UNOSA RAZGLEDNICA
                LOOP
                    INSERT INTO 
                        MEDIA (IDAPLIKACIJE,IDLOKACIJE,HEADER,SLIKA,VIDEO,FOOTER, IDCREATED)
                        
                    VALUES
                        (1,inserted_id,y.header ,y.slika, y.video, y.footer, l_created);
                    
                    commit;
        
                END LOOP;
            END IF;
        END LOOP;
    
    
    l_obj.put('h_message', 'Uspješno uneseni podaci!'); 
    l_obj.put('h_errcode', 0);
    out_json := l_obj;
        
    END;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
       common.p_errlog('p_save_data', dbms_utility.format_error_backtrace, sqlcode, sqlerrm, l_string);
       l_obj.put('h_message', SQLERRM);
       l_obj.put('h_errcode', 99);
       out_json := l_obj;
       ROLLBACK;
      
END p_save_data;
END SAVE;
