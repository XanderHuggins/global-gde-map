from pathlib import Path
import glob
import os
import subprocess
from zipfile import ZipFile
from osgeo import gdal
#root = "C:/Users/marya/Dropbox/gwflagship_gde_tnc"
root = Path(__file__).resolve().parents[1]

class Tiles:
    def __init__(self, tpath, ipath=None):
        self.fpath = tpath
        self.index_path = ipath
        self.index = None
        if ".zip" in str(tpath):
            self.zip = True
        else:
            self.zip = False

    # Gets all tile paths
    def tile_paths(self):
        if self.zip:
            path_parts = str(self.fpath).split(".zip")
            zip_fpath = path_parts[0] + ".zip"
            zipf = ZipFile(zip_fpath, "r")
            tif_paths = [
                "/vsizip/" + str(Path(zip_fpath).joinpath(zf)).replace("\\", "/")
                for zf in zipf.namelist()
                if zf.endswith(".tif")
            ]
        else:
            tif_paths = glob.glob(os.path.join(self.fpath, "*.tif"))
        return tif_paths

    # Creates tile index
    def tile_index(self, opath, oride=False):
        txt_path = f"{opath}.txt"
        shp_path = f"{opath}.shp"
        self.index_path = Path(shp_path)
        if Path(txt_path).exists() and not oride:
            print("Tile Index Already Exists")
            return True
        all_tifs = self.tile_paths()
        with open(txt_path, "w") as fl:
            for t in all_tifs:
                pth = str(t)
                if self.zip and not pth.startswith("/vsizip"):
                    pth = "/vsizip/" + pth.replace("\\", "/")
                fl.write(f"{str(pth)}\n")
        cmd = f"gdaltindex -write_absolute_path {shp_path} --optfile {txt_path}"
        subprocess.call(cmd.split())
        return True

    # Creates VRT
    def vrt_tiles(self, cache):
        vrt_folder = False
        if cache.exists():
            if str(cache)[-4:] != ".vrt":
                _, _, f = next(os.walk(cache))
                if len(f) == 0:
                    print("VRT folder empty")
                    vrt_folder = True
            if not vrt_folder:
                print("VRT path already exists")
                return cache

        # Prepare file paths within mask
        tif_paths = self.tile_paths()

        # Build VRTs
        if str(cache)[-4:] == ".vrt":  # Build mosaic VRT
            vrt = gdal.BuildVRT(str(cache), tif_paths)
            vrt.FlushCache()
        else:  # Create folder w/ pointer VRT for each file
            if not vrt_folder:
                os.makedirs(cache)
            for tp in tif_paths:
                tp_name = os.path.split(tp)[-1]
                vrt_path = cache.joinpath(f"{tp_name}.vrt")
                vrt = gdal.BuildVRT(str(vrt_path), tp)
                vrt.FlushCache()


def prep_tnc_gde():
    # Create TNC zipped tile index
    tnc=root.joinpath("data/~raw/tnc_gde/GlobalGDEMapv5-20220629T133324Z-001.zip/GlobalGDEMapv5")
    rasters=Tiles(tnc)
    rasters.tile_index(root.joinpath("data/tnc_gde/tile_index/tile_index"))

    # Create VRT
    rasters.vrt_tiles(root.joinpath("data/tnc_gde/vrt/tnc_gde.vrt"))


if __name__=='__main__':
    prep_tnc_gde()