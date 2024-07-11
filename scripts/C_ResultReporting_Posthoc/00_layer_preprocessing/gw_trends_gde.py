
import xarray as xr
import numpy as np
import mvstats as mv

# In[]
"""GLDAS pre-processing"""


def get_lon(start=-180, end=180, resolution=1):
    """
    Get new longitudes for shifting or interpolation.
    Default -180 to 180; resolution = 1 degree
    """
    return np.arange(start + (resolution) / 2., end + (resolution) / 2., resolution)


def get_lat(start=-90, end=90, resolution=1):
    """
    Get new latitudes for interpolation.
    Default -90 to 90; resolution = 1 degree
    """
    return np.arange(start + (resolution) / 2., end + (resolution) / 2., resolution)


def process_gldas21(soil_moisture, canopy, swe):
    # Regrid to 0.5 x 0.5
    soil_moisture = soil_moisture.interp(lat=get_lat(
        resolution=0.5), lon=get_lon(resolution=0.5)).compute()
    canopy = canopy.interp(lat=soil_moisture.lat,
                           lon=soil_moisture.lon).compute()
    swe = swe.interp(lat=soil_moisture.lat,
                     lon=soil_moisture.lon).compute()
    # Remove glaciers and ice caps using GRACE TWS as a mask
    tws = xr.open_dataset(
        '../../data/interim/grace_rl6v2_202112_reservoirs_gt.nc').lnd
    soil_moisture = soil_moisture.where(tws[0, ...].notnull())
    canopy = canopy.where(tws[0, ...].notnull())
    swe = swe.where(tws[0, ...].notnull())
    # Compress and save as netcdf
    soil_moisture.encoding.update({'zlib': True})
    canopy.encoding.update({'zlib': True})
    swe.encoding.update({'zlib': True})

    return soil_moisture, canopy, swe


# Load all files
ds = xr.open_mfdataset(
    '../../../../input_data/gldas/GLDAS_NOAH10_M.2.1/*.nc4', concat_dim='time')
# combine soil moisture layers
soil_moisture = (ds.SoilMoi0_10cm_inst + ds.SoilMoi10_40cm_inst +
                 ds.SoilMoi40_100cm_inst + ds.SoilMoi100_200cm_inst).compute()
canopy = ds.CanopInt_inst.compute()
swe = ds.SWE_inst.compute()
# pre-process and save as netcdfs
soil_moisture, canopy, swe = process_gldas21(soil_moisture, canopy, swe)
soil_moisture.to_netcdf(
    '../../data/interim/gldas2.1_monthly_0.5x0.5_noah_soil_moisture.nc')
canopy.to_netcdf('../../data/interim/gldas2.1_monthly_0.5x0.5_noah_canopy.nc')
swe.to_netcdf('../../data/interim/gldas2.1_monthly_0.5x0.5_noah_swe.nc')


# In []
"""Compute groundwater trends"""


def process(ts):
    """select only valid, remove climatology, and remove mean"""
    return ess.rm_mean(ess.anomaly(ts.where(valid.notnull()), how='climatology'))


# Open GRACE
tws = xr.open_dataset(
    '../../data/interim/grace_rl6v2_202205_reservoirs_gt.nc').lnd
# Mask remove GIC
mask  = ess.shift_lon_xr(xr.open_dataarray(
    '../../../tws_trends/data/interim/grace_lnd_no(ocn_ice_gic).nc'))
valid  = xr.open_dataarray('../../data/interim/valid_gfo_months.nc')
# Convert GLDAS from mm to km3 or Gt
sm_n = ess.cm_2_km3(xr.open_dataarray(
    '../../data/interim/gldas2.1_monthly_0.5x0.5_noah_soil_moisture.nc') / 10)
ca_n = ess.cm_2_km3(xr.open_dataarray(
    '../../data/interim/gldas2.1_monthly_0.5x0.5_noah_canopy.nc') / 10)
sw_n = ess.cm_2_km3(xr.open_dataarray(
    '../../data/interim/gldas2.1_monthly_0.5x0.5_noah_swe.nc') / 10)

# Apply the GIC mask
tws  = tws.where(mask.isnull())
sm_n = sm_n.where(mask.isnull())
ca_n = ca_n.where(mask.isnull())
sw_n = sw_n.where(mask.isnull())

# Compute groundwater
gws_n = tws - sm_n - ca_n - sw_n

# Compute linear trends
tw_res = mv.linear_trend_ND(process(tws))
sm_res = mv.linear_trend_ND(process(sm_n))
ca_res = mv.linear_trend_ND(process(ca_n))
sw_res = mv.linear_trend_ND(process(sw_n))
gw_res = mv.linear_trend_ND(process(gws_n))

tw_slope = tw_res[0] * 12
sm_slope = sm_res[0] * 12
ca_slope = ca_res[0] * 12
sw_slope = sw_res[0] * 12
gw_slope = gw_res[0] * 12

tw_stderr = tw_res[-1] * 12
sm_stderr = sm_res[-1] * 12
ca_stderr = ca_res[-1] * 12
sw_stderr = sw_res[-1] * 12
gw_stderr = gw_res[-1] * 12

ds = xr.Dataset(
    {
        'tw_slope': tw_slope,
        'sm_slope': sm_slope,
        'ca_slope': ca_slope,
        'sw_slope': sw_slope,
        'gw_slope': gw_slope,
        'tw_stderr': tw_stderr,
        'sm_stderr': sm_stderr,
        'ca_stderr': ca_stderr,
        'sw_stderr': sw_stderr,
        'gw_stderr': gw_stderr,
    }
)
ds.attrs['units']         = 'Gt/Yr'
ds.attrs['created by']    = 'Hrishikesh A. Chandanpurkar'
ds.attrs['creation date'] = str(ess.get_date())
ds.attrs['source']        = 'gldas_noah_groundwater.py'
ds.attrs['description']   = 'Local trends and standard error of GLDAS2.1 NOAH'
ds.to_netcdf('../../data/interim/gldas_2.1_noah_local_trends.nc')
