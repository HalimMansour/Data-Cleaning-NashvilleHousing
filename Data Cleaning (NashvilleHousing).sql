/*
Cleaning Data in SQL Queries
Auther: Halim
*/

-----------------------------------------------------------------------------------------------------------------------------------------
-- Retrieve all records from the NashvilleHousing table
-----------------------------------------------------------------------------------------------------------------------------------------

SELECT *
FROM DataCleaning.dbo.NashvilleHousing;


-----------------------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format
-----------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD SaleDateConverted DATE;

-- Convert SaleDate to the standardized date format
UPDATE DataCleaning.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate);


-----------------------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data
-----------------------------------------------------------------------------------------------------------------------------------------

-- Find matching ParcelIDs where one has a null PropertyAddress and the other has a non-null PropertyAddress
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning.dbo.NashvilleHousing a
JOIN DataCleaning.dbo.NashvilleHousing b ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Update PropertyAddress for records with null values by using a non-null PropertyAddress from matching ParcelIDs
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning.dbo.NashvilleHousing a
JOIN DataCleaning.dbo.NashvilleHousing b ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;


-----------------------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)
-----------------------------------------------------------------------------------------------------------------------------------------

-- Retrieve the PropertyAddress column from the NashvilleHousing table
SELECT PropertyAddress
FROM DataCleaning.dbo.NashvilleHousing;

-- Add a new column PropertySplitAddress and populate it with the address part before the comma
ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

-- Update PropertySplitAddress column with the address part before the comma
UPDATE DataCleaning.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

-- Add a new column PropertySplitCity and populate it with the city part after the comma
ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

-- Update PropertySplitCity column with the city part after the comma
UPDATE DataCleaning.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


-- Retrieve the OwnerAddress column from the NashvilleHousing table
SELECT OwnerAddress
FROM DataCleaning.dbo.NashvilleHousing;

-- Split OwnerAddress into separate columns for address, city, and state
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitState
FROM DataCleaning.dbo.NashvilleHousing;

-- Add a new column OwnerSplitAddress and populate it with the address part
ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

-- Update OwnerSplitAddress column with the address part from OwnerAddress
UPDATE DataCleaning.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

-- Add a new column OwnerSplitCity and populate it with the city part
ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

-- Update OwnerSplitCity column with the city part from OwnerAddress
UPDATE DataCleaning.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

-- Add a new column OwnerSplitState and populate it with the state part
ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

-- Update OwnerSplitState column with the state part from OwnerAddress
UPDATE DataCleaning.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


-----------------------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field
-----------------------------------------------------------------------------------------------------------------------------------------

-- Retrieve distinct values of SoldAsVacant and their count
SELECT
    DISTINCT SoldAsVacant,
    COUNT(SoldAsVacant)
FROM
    DataCleaning.dbo.NashvilleHousing
GROUP BY	
    SoldAsVacant
ORDER BY
    2;

-- Replace Y and N values in SoldAsVacant with Yes and No respectively
SELECT
    SoldAsVacant,
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END
FROM
    DataCleaning.dbo.NashvilleHousing;

-- Update SoldAsVacant column with Yes and No values
UPDATE
    DataCleaning.dbo.NashvilleHousing
SET
    SoldAsVacant = CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;


-----------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates
-----------------------------------------------------------------------------------------------------------------------------------------

-- CTE to assign row numbers based on duplicates within specific columns
WITH RowNumCTE AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM
        DataCleaning.dbo.NashvilleHousing
)
-- Retrieve records with row number greater than 1, indicating duplicates
SELECT *						-- To remove duplicates row you need to use "DELETE" insted of "SELECT *" --
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;


-----------------------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns
-----------------------------------------------------------------------------------------------------------------------------------------

-- Drop the specified columns from the NashvilleHousing table
ALTER TABLE DataCleaning.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;


-----------------------------------------------------------------------------------------------------------------------------------------
-- Retrieve all records from the NashvilleHousing table
-----------------------------------------------------------------------------------------------------------------------------------------

SELECT *
FROM DataCleaning.dbo.NashvilleHousing;
