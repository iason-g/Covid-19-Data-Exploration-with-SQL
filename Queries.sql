-- Deaths due to Covid-19
SELECT *
FROM [MyDB].[dbo].[CovidDeaths]

-- Vaccinations against Covid-19
FROM * 
SELECT [MyDB].[dbo].[CovidVaccinations]

-- Total cases, total deaths and death rate per day, per country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM [MyDB].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Total cases per country
SELECT location, date, population, total_cases,  (total_cases/population)*100 AS population_infected_rate
FROM [MyDB].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Countries with the highest total infected population
SELECT location, population, MAX(total_cases) AS total_infected,  MAX((total_cases/population))*100 AS population_infected_rate
FROM [MyDB].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_infected_rate DESC

-- Continents with the highest death count
SELECT location, MAX(total_deaths) AS total_death_count 
FROM [MyDB].[dbo].[CovidDeaths]
WHERE continent IS NULL AND iso_code NOT IN ('OWID_EUN', 'OWID_WRL', 'OWID_INT', 'OWID_LIC', 'OWID_LMC', 'OWID_UMC', 'OWID_HIC')
GROUP BY location
ORDER BY total_death_count DESC

-- Countries with the highest death count
SELECT location, MAX(total_deaths) AS total_death_count 
FROM [MyDB].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Total global cases, deaths and death rate
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS mortality_rate
FROM [MyDB].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total vaccinations per day, per country
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM [MyDB].[dbo].[CovidDeaths] AS d
JOIN [MyDB].[dbo].[CovidVaccinations] AS v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2, 3

-- Using CTE to perform calculations on Partition By in previous query
WITH PopulationVaccinatedPercent (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM [MyDB].[dbo].[CovidDeaths] AS d
JOIN [MyDB].[dbo].[CovidVaccinations] AS v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL)

SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_people_vaccinated_rate
FROM PopulationVaccinatedPercent

-- Using Temporary Table to perform calculations on Partition By in previous query
DROP TABLE IF EXISTS #PopulationVaccinatedPercent
CREATE TABLE #PopulationVaccinatedPercent (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric)

INSERT INTO #PopulationVaccinatedPercent
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM [MyDB].[dbo].[CovidDeaths] AS d
JOIN [MyDB].[dbo].[CovidVaccinations] AS v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_people_vaccinated_rate
From #PopulationVaccinatedPercent

-- Creating View to store data for later visualizations
CREATE VIEW PopulationVaccinatedPercent AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM [MyDB].[dbo].[CovidDeaths] AS d
JOIN [MyDB].[dbo].[CovidVaccinations] AS v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *
FROM [MyDB].[dbo].[PopulationVaccinatedPercent]
