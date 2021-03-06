/*_________________________________________
|       DE MATOS RIBEIROS Romain           |
|            MULLER Léane                  |
____________________________________________ */

/* Requêtes d’interrogation */

/* 1- Quel pourcentage des sessions déjà réalisées comporte des employés inscrits provenant d'au moins 4 entreprises différentes ? */

CREATE TEMPORARY TABLE table1
    SELECT s.no_session
    FROM session s, inscrit2 ins2, employe emp, adherent adh, type_adh t_adh
    WHERE s.no_session = ins2.no_session
    AND ins2.no_emp = emp.no_emp
    AND emp.no_adh = adh.no_adh
    AND adh.no_type_adh = t_adh.no_type_adh
    AND nom_type_adh = "Entreprise"
    GROUP BY s.no_session
    HAVING COUNT(adh.no_adh)>= 4;
    
CREATE TEMPORARY TABLE table2
    SELECT COUNT(*) n2
    FROM table1;
    
CREATE TEMPORARY TABLE table3
    SELECT COUNT(no_session) n1
    FROM session
    WHERE date_deb < CURDATE();
                          
    SELECT (n2*100)/n1
    FROM table2, table3;

/* 2- Quel est, pour chacune des sessions démarrant en 2018 ou 2019 et portant sur le thème
« Bases de Données », le nombre d’inscrits de type adhérent « individuel » (attention
au cas 0) ? */

CREATE TEMPORARY TABLE table1 
    SELECT COUNT(no_adh), session.no_session
    FROM theme, session, inscrit1
    WHERE theme.no_theme = session.no_theme
    AND session.no_session = inscrit1.no_session
    AND lib_theme = "Base de Données"
    AND (date_deb <= "2018-01-01"
    OR date_deb >= "2019-01-01")
    GROUP BY session.no_session /* <-- on partionne sur le nombre de sessions */
    ;
CREATE TEMPORARY TABLE table2 
    SELECT no_session, 0
    FROM inscrit1
    WHERE no_session NOT IN 
    (
        SELECT no_session
        FROM session, theme
        WHERE theme.no_theme = session.no_theme
    );
SELECT no_session 
FROM table1
UNION
SELECT no_session 
FROM table2 

/* 3- Quel est, pour chacune des sessions ayant démarré en 2020, le pourcentage de participants inscrits par une entreprise et le pourcentage de articipants individuels ? */

CREATE TEMPORARY TABLE table1
SELECT session.no_session, COUNT(no_adh) AS n1
FROM inscrit1, session
WHERE YEAR(date_deb)=2020
AND session.no_session=inscrit1.no_session
GROUP BY session.no_session
UNION 
SELECT session.no_session,0
FROM session, inscrit1
WHERE YEAR(date_deb)=2020
AND session.no_session NOT IN(
    SELECT session.no_session
    FROM session, inscrit1
    WHERE YEAR(date_deb)=2020
    AND session.no_session=inscrit1.no_session)
;
CREATE TEMPORARY TABLE table2
SELECT session.no_session, COUNT(no_emp) AS n2
FROM inscrit2, session
WHERE YEAR(date_deb)=2020
AND session.no_session=inscrit2.no_session
GROUP BY session.no_session
UNION
SELECT session.no_session,0
FROM session, inscrit2
WHERE YEAR(date_deb)=2020
AND session.no_session NOT IN(
    SELECT session.no_session
    FROM session, inscrit2
    WHERE YEAR(date_deb)=2020
    AND session.no_session=inscrit2.no_session)
;
SELECT session.no_session, (n2*100)/n1 AS pct_entreprise, (n2*100)/n1 AS pct_indiv
FROM table1, table2, session
WHERE session.no_session=table1.no_session
AND session.no_session=table2.no_session
GROUP BY session.no_session
;

/* 4- Quels adhérents de type entreprise ont inscrit au moins un employé à des sessions
démarrant en 2019 portant sur tous les thèmes pour lesquels il y a eu des sessions cette
année là ? */

SELECT adherent.no_adh, nom_adh
FROM adherent,type_adh, employe, inscrit2, session
WHERE adherent.no_type_adh=type_adh.no_type_adh
AND nom_type_adh = "Entreprise"
AND YEAR(date_deb) = '2019'
AND employe.no_adh = adherent.no_adh
AND employe.no_emp = inscrit2.no_emp
AND inscrit2.no_session = session.no_session
GROUP BY adherent.no_adh, adherent.nom_adh
HAVING COUNT(*) >= 1
AND NOT EXISTS (
    SELECT no_theme
    FROM theme
    WHERE no_theme NOT IN(
        SELECT session.no_theme
        FROM session
        WHERE year(date_deb)='2019'
    )
)

/* 5- Quels sont les thèmes pour lesquels au moins une session a été organisée lors de chacune des 3 dernières années révolues ? */

select distinct session.no_session,session.no_theme
    from theme,session
    where year(date_deb)=2020 
    and year(date_deb)=2019 
    and year(date_deb)=2018
    and theme.no_theme=session.no_theme 
    group by session.no_session,session.no_session
    having no_session>=1

/* 6- Quels animateurs ont participé à l’animation de toutes les sessions portant sur le thème
« Bases de Données » et démarrant en 2018 ou 2019 ? */
/* Condition : 2018 || 2019 = et (condition) / et ((annee(date_deb)=2018) ou (annee(date_deb)=2019))*/
/* /!\ Attention aux parenthèses /!\ */

SELECT DISTINCT no_anim, nom_anim, prenom_anim
FROM animateur
WHERE NOT EXISTS (
    SELECT no_session
    FROM session, theme
    WHERE ((YEAR(date_deb)=2018) OR (YEAR(date_deb)=2019))
    AND session.no_theme = theme.no_theme
    AND lib_theme = "Base de Données"
    AND no_session NOT IN (
        SELECT no_session
        FROM anime
        WHERE anime.no_anim = animateur.no_anim
    )
)

/* 7- Pour tous les salaires versés en 2020, quel est le pourcentage correspondant aux prises de responsabilités et le pourcentage correspondant aux heures de formation ?*/

create temporary table table1
    select sum(prime)+(taux_heure*nb_heures) n1
    from anime, session
    where session.no_session = anime.no_session
    and ( year(date_sal) = 2020);

create temporary table table2
    select sum(prime) n2
    from anime, session
    where session.no_session = anime.no_session
    and ( year(date_sal) = 2020);
    
create temporary table table3
    select (taux_heure*nb_heures) n3
    from anime, session
    where session.no_session = anime.no_session
    and ( year(date_sal) = 2020);
    
select ((n2*100)/n1) as prises_de_resp, ((n3*100)/n1) as heures_de_formation
    from table1, table2, table3;

/* 8- Quelles sont les 10 sessions démarrant en 2019 pour lesquelles les dépenses (prime de
responsabilité + coût des heures de formation) ont été les plus élevées et classées dans
l’ordre décroissant de ces dépenses ? */

CREATE TEMPORARY TABLE T1
SELECT session.no_session,SUM(prix+(nb_heures*taux_heure)+prime) depenses
FROM session, anime
WHERE session.no_session = anime.no_session
AND (YEAR(date_deb)=2019)
GROUP BY no_session;

CREATE TEMPORARY TABLE T2
SELECT COUNT(*)n1, table1.no_session, table1.depenses
FROM T1 table1,T1 table2
WHERE table1.depenses <= table2.depenses
GROUP BY table1.no_session,table1.depenses;

CREATE TEMPORARY TABLE T3
SELECT depenses,COUNT(*)n2
FROM T1
GROUP BY depenses;

SELECT (n1+1)-n2 classt, T2.no_session, T2.depenses
FROM T2, T3
WHERE T2.depenses = T3.depenses
AND (n1+1)-n2 <= 10
ORDER BY classt;

/* Requête de vérification de cohérence */

/* 9- Existe-t-il des sessions pour lesquelles l'animateur responsable de la session ne fait pas partie de l'ensemble des animateurs de la session ?*/

select no_session
from session
where NOT EXISTS
    (select no_anim
     from animateur
     where no_anim NOT IN
        (select session.no_anim_resp
         from anime, animateur
         where session.no_anim_resp = animateur.no_anim))

/* 10- Existe-t-il des animateurs qui ont été responsables d’une session portant sur un thème
dont ils ne sont pas spécialistes ? */

SELECT animateur.nom_anim, animateur.prenom_anim, animateur.no_anim
FROM animateur
WHERE  NOT EXISTS(
    SELECT session.no_anim_resp
    FROM session
    WHERE session.no_anim_resp NOT IN(
        SELECT specialite.no_anim
        FROM specialite,session
        WHERE specialite.no_theme = session.no_theme
        AND session.no_anim_resp = animateur.no_anim
        UNION
        SELECT session.no_anim_resp
        FROM specialite,session
        WHERE specialite.no_theme = session.no_theme
        AND session.no_anim_resp = animateur.no_anim
    )
)

/* Résultat de requêtes */

/* Requête 1 */
   /*   _____________
       | (n2*100)/n1 |
       |-------------|
       |0.000        |
       |_____________|  */


/* Résultat Requête 2 :
Nombre d'inscrit.s      no_session
3                       S9        
5                       S10
0                       S3              */


/* Requête 3 */ 
                  
      /* MySQL a retourné un résultat vide  */


/* Résultat Requête 4 :
Numero adherent         Nom adherent
1                       IUT Metz
3                       IDMC                 */


/* Requête 5 */   
   
      /* MySQL a retourné un résultat vide  */


/* Résultat Requête 6 :
Numero animateur        Nom animateur        Prenom animateur  
AN1                     COVER                Harry              */


 /* Requête 7 */
/*     ____________________________________________
       | prises_de_resp      | heures_de_formation |
       |---------------------|---------------------|
       |33.333               | 66.667              |
       |_____________________|_____________________|
       |33.333               |33.333               |
       |_____________________|_____________________|   */


/* Résultat Requête 8 :
classt                  no_session              depenses        
10                      S3                      5837
9                       S5                      4789                 
8                       S10                     4532
7                       S8                      3475
6                       S4                      3298
5                       S1                      2876
4                       S7                      2530
3                       S2                      2189
2                       S6                      1896
1                       S9                      1598                */

         
 /* Requête 9 */
         
      /* MySQL a retourné un résultat vide  */
         

/* Résultat Requête 10 :


MySQL a retourné un résultat vide (aucune ligne). (Traitement en 0.0016 secondes.)
Ici, il n'existe donc pas d'animateur ayant été responsable d'un thème dont ils ne sont pas spécialistes
*/ 