/* Requêtes d’interrogation */

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

/* 4- Quels adhérents de type entreprise ont inscrit au moins un employé à des sessions
démarrant en 2019 portant sur tous les thèmes pour lesquels il y a eu des sessions cette
année là ? */

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
    AND no_session NOT IN (
        SELECT no_session
        FROM anime
        WHERE anime.no_anim = animateur.no_anim
    )
)

/* 8- Quelles sont les 10 sessions démarrant en 2019 pour lesquelles les dépenses (prime de
responsabilité + coût des heures de formation) ont été les plus élevées et classées dans
l’ordre décroissant de ces dépenses ? */

CREATE TEMPORARY TABLE T1
SELECT s.no_session,SUM(prix+(nb_heures*taux_heure)+prime)d
FROM session s,anime a
WHERE s.no_session = a.no_session
AND (year(date_deb)=2019)
GROUP BY no_session;

CREATE TEMPORARY TABLE T2
SELECT COUNT(*)n1,R1.no_session,R1.d
FROM T1 R1,T1 R2
WHERE R1.d <= R2.d
GROUP BY R1.no_session,R1.d;
CREATE TEMPORARY TABLE T3
SELECT d,COUNT(*)n2
FROM T1
GROUP BY d;
SELECT n1+1-n2 classt,T2.no_session,T2.d
FROM T2,T3
WHERE T2.d = T3.d
AND n1+1-n2 <=10
ORDER BY classt;

/* Requête de vérification de cohérence */

/* 10- Existe-t-il des animateurs qui ont été responsables d’une session portant sur un thème
dont ils ne sont pas spécialistes ? */


/* Synthaxe de l'UNION :
SELECT * FROM table1
UNION
SELECT * FROM table2 */