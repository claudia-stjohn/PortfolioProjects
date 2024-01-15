-- Drop existing temp tables if they exist
IF OBJECT_ID('tempdb..#TempObesity', 'U') IS NOT NULL
    DROP TABLE #TempObesity;

IF OBJECT_ID('tempdb..#TempDeath', 'U') IS NOT NULL
    DROP TABLE #TempDeath;

IF OBJECT_ID('tempdb..#Rank1', 'U') IS NOT NULL
    DROP TABLE #Rank1;

IF OBJECT_ID('tempdb..#IntegratedTable', 'U') IS NOT NULL
    DROP TABLE #IntegratedTable;

-- #TempObesity
-- Obesity rate by state in 2015
SELECT State, Obesity
INTO #TempObesity
FROM [SQL Data Exploration Project].[dbo].[Obesity]
ORDER BY Obesity DESC;

-- #TempDeath
-- Death Rate adjusted for age by state in 2015
SELECT Year, Cause_Name, State, Death_Rate
INTO #TempDeath
FROM [SQL Data Exploration Project].[dbo].[Death]
WHERE Year = 2015
ORDER BY Death_Rate DESC;

-- CTE to show leading cause of death by state in 2015
WITH RankedDeaths AS (
    SELECT State, 
	Cause_Name AS Leading_Cause, 
	ROW_NUMBER() OVER (PARTITION BY State ORDER BY Death_Rate DESC) AS Rank
    FROM #TempDeath
    WHERE Cause_Name <> 'All causes'
)

-- #Rank1
-- Leading cause of death
SELECT State, Leading_Cause, Rank
INTO #Rank1
FROM RankedDeaths
WHERE Rank = 1;

-- Percent of states where heart disease is leading cause
SELECT 
	COUNT(CASE WHEN Leading_Cause = 'Heart disease' THEN 1 END) AS StatesWithHeartDisease,
	COUNT(CASE WHEN Leading_Cause = 'Heart disease' THEN 1 END) * 100.0 / COUNT(*) AS Percentage
FROM #Rank1;

-- Percent of states where cancer is leading cause
SELECT 
	COUNT(CASE WHEN Leading_Cause = 'Cancer' THEN 1 END) AS StatesWithCancer,
	COUNT(CASE WHEN Leading_Cause = 'Cancer' THEN 1 END) * 100.0 / COUNT(*) AS Percentage
FROM #Rank1;

-- Percent of states where other is leading cause
SELECT 
	COUNT(CASE WHEN Leading_Cause <> 'Cancer' AND Leading_Cause <> 'Heart disease' THEN 1 END) AS StatesWithOther,
	COUNT(CASE WHEN Leading_Cause <> 'Cancer' AND Leading_Cause <> 'Heart disease' THEN 1 END) * 100.0 / COUNT(*) AS Percentage
FROM #Rank1;

-- Top 3 Causes of Death by State
WITH RankedCauses AS (
    SELECT State, Cause_Name,Death_Rate,
        ROW_NUMBER() OVER (PARTITION BY State ORDER BY Death_Rate DESC) AS Rank
    FROM #TempDeath
    WHERE Cause_Name <> 'All causes'
)

-- Top 3 causes of death by state
SELECT 
    State,Cause_Name,Death_Rate,Rank
FROM RankedCauses
WHERE Rank <= 3;

-- Integrated table comparing Obesity rates vs leading cause of death
SELECT
    O.State,
    O.Obesity,
    R1.Leading_Cause,
    R1.Rank
INTO #IntegratedTable
FROM #TempObesity O
JOIN #Rank1 R1 ON O.State = R1.State;

SELECT *
FROM #IntegratedTable;

-- Table of obesity rates of states where heart disease is leading cause
SELECT *
FROM #IntegratedTable
WHERE Leading_Cause = 'Heart disease';

-- Table of obesity rates of states where cancer is leading cause
SELECT *
FROM #IntegratedTable
WHERE Leading_Cause = 'Cancer';
