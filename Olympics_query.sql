drop table if exists OLYMPICS_HISTORY;
create table if not exists OLYMPICS_HISTORY
(
	id int,
	name varchar,
	sex varchar,
	age varchar,
	height varchar,
	weight varchar,
	team varchar,
	noc varchar,
	games varchar,
	year int,
	season varchar,
	city varchar,
	sport varchar,
	event varchar,
	medal varchar
);

drop table if exists OLYMPICS_HISTORY_NOC_REGIONS;
create table if not exists OLYMPICS_HISTORY_NOC_REGIONS
(
	noc varchar,
	region varchar,
	notes varchar
	
);
select * from OLYMPICS_HISTORY;
select * from OLYMPICS_HISTORY_NOC_REGIONS;


### Question#####
--1:How many olympics games have been held?
	
select count(distinct games) as total_Olympics_games 
from olympics_history

--2: List down all Olympics games held so far?

select distinct year,season,city
from olympics_history
order by year

--3:Mention the total no of nations who participated in each olympics game?

SELECT 
    oh.year, 
    oh.season, 
    COUNT(DISTINCT oh.noc) AS Number_of_nations
FROM 
    olympics_history AS oh
JOIN 
    olympics_history_noc_regions AS nr ON oh.noc = nr.noc
GROUP BY 
    oh.year, 
    oh.season
ORDER BY 
    oh.year, 
    oh.season;


--4:Which year saw the highest and lowest no of countries participating in olympics?

-- higest no of countries
select oh.year,oh.season,
count(distinct oh.noc) as higest_countries
from olympics_history as oh
join olympics_history_noc_regions as nr on oh.noc = nr.noc
group by oh.year,oh.season
order by higest_countries desc
limit 1;

-- lowest no of countries
select oh.year,oh.season,
count(distinct oh.noc) as higest_countries
from olympics_history as oh
join olympics_history_noc_regions as nr on oh.noc = nr.noc
group by oh.year,oh.season
order by higest_countries 
limit 1;

-- 5: Which nation has participated in all of the olympic games

-- Step 1: Find the total number of unique Olympic Games
with unique_games as(
	select distinct games
	from olympics_history
	),
					
-- Step 2: Count the number of unique games each NOC has participated in

noc_participation as (
	select oh.noc,
	count(distinct oh.games) as participation_count
	from olympics_history as oh
	group by oh.noc
	
)

-- Step 3: Find the NOC(s) that have participated in all unique games
SELECT
    np.noc,
    nr.region,
    np.participation_count
FROM
    noc_participation AS np
JOIN
    olympics_history_noc_regions AS nr ON np.noc = nr.noc
WHERE
    np.participation_count = (SELECT COUNT(*) FROM unique_games);

--Q6:-Identify the sport which was played in all summer olympics.

select season,sport,year
from olympics_history
where season='Summer'
group by sport,season,year
order by year desc

--Q7:-Which Sports were just played only once in the olympics?

	
select sport,count(distinct games) as occurrence_count
from olympics_history
group by sport
having count(distinct games)=1;
 
--8:-Fetch the total no of sports played in each olympic games.


select games,count(distinct sport) as total_no_of_sport 
from olympics_history
group by games


--9:-Fetch details of the oldest athletes to win a gold medal.

with oldest_gold_medalist as (
	select max(age) as max_age
	from olympics_history
	where medal='Gold' and age != 'NA'  
)

select *
from olympics_history
where medal='Gold' and age=(select max_age from oldest_gold_medalist)
order by age desc;


--10:-Find the Ratio of male and female athletes participated in all olympic games.

with unique_games as(
	select distinct games
	from olympics_history
),
athlete_participation as(
	select id,name,sex, 
	count(distinct games) as participation_count
	from olympics_history
	group by id,name,sex
),
athletes_in_all_games as(
	select ap.id,ap.name,ap.sex
	from athlete_participation as ap
	where ap.participation_count=(select count(*) from unique_games)
 ),

sex_count as(
	select sex, count(*) as count
	from athletes_in_all_games 
	group by sex
	)

SELECT
    (SELECT COUNT(*) FROM sex_count WHERE Sex = 'M')::float /
    (SELECT COUNT(*) FROM sex_count WHERE Sex = 'F')::float AS male_to_female_ratio;

--11:-Fetch the top 5 athletes who have won the most gold medals?


select name,team,count(*) as gold_medal_count
from olympics_history
where medal='Gold'
group by name,team
order by gold_medal_count desc
limit 5;

--12:-Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).


select name,team,count(*) as total_count
from olympics_history
where medal='Gold'or medal='Silver'or medal='Bronze'
group by name,team
order by total_count desc
limit 5;


--13. Fetch the top 5 most successful countries in olympics.Success is defined by no of medals won?

select nr.region,count(1) as total_medals
from olympics_history as oh
join olympics_history_noc_regions as nr on oh.noc=nr.noc
where medal !='NA'
group by nr.region
order by total_medals desc
limit 5;

--14. List down total gold, silver and bronze medals won by each country.


create extension tablefunc;

select country
	,coalesce(gold,0) as gold
	,coalesce(silver,0) as silver 
	,coalesce(bronze,0) as bronze
	
from crosstab(
	'select nr.region as country,medal,count(1) as total_medals
from olympics_history as oh
join olympics_history_noc_regions as nr on oh.noc=nr.noc
where medal !=''NA''
group by nr.region,medal
order by nr.region,medal',
'values (''Bronze''),(''Gold''),(''Silver'')')
as final_result(country varchar,bronze bigint,gold bigint,silver bigint)
order by gold desc,silver desc,bronze desc;



--15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.



SELECT substring(games,1,position(' - ' in games) - 1) as games
        , substring(games,position(' - ' in games) + 3) as country
        , coalesce(gold, 0) as gold
        , coalesce(silver, 0) as silver
        , coalesce(bronze, 0) as bronze
    FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
                , medal
                , count(1) as total_medals
                FROM olympics_history oh
                JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint);



--17. Which countries have never won gold medal but have won silver/bronze medals?

select * from(
	select country
	,coalesce(gold,0) as gold
	,coalesce(silver,0) as silver
	,coalesce(bronze,0) as bronze

	from crosstab('select nr.region as country,medal,count(1) as total_medals
	from olympics_history oh
	join olympics_history_noc_regions as nr on oh.noc=nr.noc
	where medal!=''NA''
	group by nr.region,medal
	order by nr.region,medal',
	'values('' Bronze''),(''Gold''),(''Silver'')')
	AS FINAL_RESULT(country varchar,
    		bronze bigint, gold bigint, silver bigint)) x
    where gold = 0 and (silver > 0 or bronze > 0)
    order by gold desc nulls last, silver desc nulls last, bronze desc nulls last;


--18:-In which Sport/event, India has won highest medals.

select sport,count(1) as total_medal
from olympics_history
where medal<>'NA' and team='India'
group by sport
order by total_medal desc
limit 1;


--19:- Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

select team,sport,games,count(1) as total_medal
from olympics_history
where medal<>'NA' and team='India' and sport='Hockey'
group by team,sport,games
order by total_medal desc;


--20:- In which Sport/event, India athletes won the top 5 most medals in and ,how many medals have they won in each sport.

select sport,count(1) as total_medal
from olympics_history
where medal<>'NA' and team='India'
group by sport
order by total_medal desc
limit 5;


