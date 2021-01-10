using PowerSystems;

DATA_DIR = download(PowerSystems.UtilsData.TestData, folder = pwd())

system_data = System(joinpath(DATA_DIR, "matpower/case5.m"))