Select * 
From Project..CovidDeaths
--where continent is not null
Order by 3, 4

Select *
From Project..CovidVaccinations
Order by 3, 4

--SELECT DATA THAT WE ARE GOING TO BE USING

SELECT location, date, total_cases, new_cases, total_deaths, population
From Project..CovidDeaths
Order by 1, 2

--Looking at Total cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Project..CovidDeaths
Where location like '%states%'
Order by 1, 2

--Looking at Total cases vs Population
--Show what percentage of population got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as TotalCasesPercentage
FROM Project..CovidDeaths
WHERE location like '%states%'
and continent is not null
Order by 1, 2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 
as PercentagePopulationInfected
FROM Project..CovidDeaths
--WHERE location like '%states%' and where continent is not null
GROUP BY location, population
Order by PercentagePopulationInfected desc

--Showing Countries with Highest Death Count per Population
--Let's break things down by continent

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
--, (total_deaths/population)*100 
--as HightestDeathPerPopulation
FROM Project..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--Global Numbers
SELECT date, SUM(new_cases) as NewCases, SUM(cast(new_deaths as int)) as TotalDeaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Project..CovidDeaths
where continent is not null
Group by date
Order by 1, 2

--Looking at Total Population vs Vacciantions

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.date) as VaccinationPartByLocation
FROM Project..CovidVaccinations dea
Join Project..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

--USE CTE

WITH PopVsVac (continent, location, date, population, new_vacciantions, VacciantionPartByLocation)
as(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.date, dea.location) 
as VaccinationPartByLocation
FROM Project..CovidVaccinations dea
Join Project..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
SELECT *, (VaccinationPartByLocation/population)*100 as VacPercentage
FROM PopVsVac

--Temp table

DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
VaccinationPartByLocation numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.date, dea.location) 
as VaccinationPartByLocation
FROM Project..CovidVaccinations dea
Join Project..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date

SELECT *, (VaccinationPartByLocation/population)*100 as VacPercentage
FROM #PercentPopulationVaccinated

--Creating View to store data later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.date, dea.location) 
as VaccinationPartByLocation
FROM Project..CovidVaccinations dea
Join Project..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

Select *
FROM PercentPopulationVaccinated