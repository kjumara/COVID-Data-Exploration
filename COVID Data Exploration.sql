/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Selecting Data We are Going to Be Starting With

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is NOT NULL
ORDER BY location, date

-- Comparing Total Cases to Total Deaths
-- Liklihood of Death if Covid is Contracted in the United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location like '%states%'
AND continent is NOT NULL
ORDER BY 1,2

-- Comparing Total Cases to Population
-- Shows What Percentage of the Population has Contracted Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Percent_Population_Infected
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location like '%states%'
ORDER BY 1,2

-- Viewing Countries with the Highest Infection Rate Compared to their Population

SELECT location, population, max(total_cases) as Highest_Infection_Count, MAX((total_cases/population))*100 as Percent_Population_Infected
FROM PortfolioProject.dbo.CovidDeaths$
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC

-- Viewing Countries with the Death Count Compared to their Population

SELECT location, max(cast(total_deaths as int)) as Total_Death_Count, MAX((total_deaths/population))*100 as Percent_Population_Killed
FROM PortfolioProject.dbo.CovidDeaths$
GROUP BY location
ORDER BY Percent_Population_Killed DESC

-- Breaking Death Rate Down by Continent

SELECT continent, max(cast(total_deaths as int)) as Total_Death_Count, MAX((total_deaths/population))*100 as Percent_Population_Killed
FROM PortfolioProject.dbo.CovidDeaths$
GROUP BY continent
ORDER BY Percent_Population_Killed DESC


-- Global Numbers

SELECT sum(new_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as Death_Percentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1,2 

-- Comparing Total Population to Total Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location) as Rolling_Sum_of_Vaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 1,2,3

-- Using CTE
WITH Pop_vs_Vac (date, location, population, new_vaccinations, Rolling_Sum_of_Vaccinated)
as 
(
SELECT dea.date, dea.location, population, vac.new_vaccinations, 
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location) as Rolling_Sum_of_Vaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
)
Select *, (Rolling_Sum_of_Vaccinated/Population)*100 as Percentage_Vaccinated
From Pop_vs_Vac

-- Using Temp Table
DROP TABLE IF EXISTS #PopulationVaccinated
CREATE TABLE #PopulationVaccinated(
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_Sum_of_Vaccinated numeric
)

INSERT INTO #PopulationVaccinated
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_Sum_of_Vaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	On dea.location = vac.location
	AND dea.date = vac.date

Select *, (Rolling_Sum_of_Vaccinated/Population)*100 as Percent_Vaccinated
From #PopulationVaccinated

--Creating View To Store Data for Later Visualizations

CREATE VIEW Percent_Population_Vaccinated as
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_Sum_of_Vaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM Percent_Population_Vaccinated

