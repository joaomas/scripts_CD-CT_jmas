#!/usr/bin/env python3
import sys
import cdsapi

# -------------------------------------
# LER ARGUMENTO YYYYMMDDHH
# -------------------------------------
if len(sys.argv) != 2:
    print("Uso: python3 script.py YYYYMMDDHH")
    sys.exit(1)

data = sys.argv[1]

if len(data) != 10 or not data.isdigit():
    print("ERRO: A data deve estar no formato YYYYMMDDHH (ex: 2025102500)")
    sys.exit(1)

YEAR  = data[0:4]
MONTH = data[4:6]
DAY   = data[6:8]
TIMES = data[8:10]


print(f"Fazendo downloado para a data - {YEAR}{MONTH}{DAY}{TIMES}")

# -------------------------------------
# ARQUIVOS DE SAIDA
# -------------------------------------
OUT_PL = f'era5_{YEAR}{MONTH}{DAY}{TIMES}_pl.grib'
OUT_SL = f'era5_{YEAR}{MONTH}{DAY}{TIMES}_sl.grib'

# -------------------------------------
# INICIALIZAR CLIENTE CDS
# -------------------------------------
c = cdsapi.Client()

# -------------------------------------
# DOWNLOAD: PRESSURE LEVELS
# -------------------------------------
print("Baixando ERA5 Pressure Levels...")
c.retrieve(
    'reanalysis-era5-pressure-levels',
    {
        'product_type': 'reanalysis',
        'format': 'grib',

        'variable': [
            'temperature',
            'geopotential',
            'u_component_of_wind',
            'v_component_of_wind',
            'relative_humidity',
            "specific_humidity",
        ],

        'pressure_level': [
            '10', '30', '50', '70', '100', '150', '200', '250', '300', '350',
            '400', '500', '600', '650', '700', '750', '775', '800', '825',
            '850', '875', '900', '925', '950', '975', '1000'    	    
        ],

        'year': YEAR,
        'month': MONTH,
        'day': DAY,
        'time': TIMES,
    },
    OUT_PL
)
print(f"Arquivo salvo: {OUT_PL}")

# -------------------------------------
# DOWNLOAD: SINGLE LEVELS
# -------------------------------------
print("Baixando ERA5 Single Levels...")
c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type': 'reanalysis',
        'format': 'grib',

        'variable': [
            '10m_u_component_of_wind',
            '10m_v_component_of_wind',
            '2m_temperature',
            '2m_dewpoint_temperature',
            'surface_pressure',
            'mean_sea_level_pressure',
            'land_sea_mask',
            'sea_ice_cover',
            'sea_surface_temperature',
            'skin_temperature',
            'snow_depth',    
	    'snow_density', 
            'soil_temperature_level_1',
            'soil_temperature_level_2',
            'soil_temperature_level_3',
            'soil_temperature_level_4',
            'volumetric_soil_water_layer_1',
            'volumetric_soil_water_layer_2',
            'volumetric_soil_water_layer_3',
            'volumetric_soil_water_layer_4',
            'geopotential',
        ],

        'year': YEAR,
        'month': MONTH,
        'day': DAY,
        'time': TIMES,
    },
    OUT_SL
)
print(f"Arquivo salvo: {OUT_SL}")

print("\nDownload ERA5 concluido com sucesso!")
