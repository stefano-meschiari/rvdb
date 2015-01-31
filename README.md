# rvdb 0.1

## What it is
**rvdb** is a repository of the radial velocity datasets that have been published in peer-reviewed literature, and is the default set of data that is distributed with [Systemic](http://www.stefanom.org/systemic). The repository is browsable online at http://www.rvdb.io or using [Systemic Live](http://www.stefanom.org/systemic-online), and is easily downloadable in its entirety with git:

```
git clone https://github.com/stefano-meschiari/rvdb.git
```
or by downloading the [.tar.gz archive](https://github.com/stefano-meschiari/rvdb/raw/master/rvdb.tar.gz).

**Note**: This database is currently in a pre-release version. Please check the data carefully before using it for scientific work. If you notice any issues with one of the datasets, please do a pull request on this repository, [file a bug](https://github.com/stefano-meschiari/rvdb/issues), or [drop me a line](http://www.stefanom.org).

## What it contains
The repository is structured as a collection of plain-text files that can easily be imported in [Systemic](http://www.stefanom.org/systemic) or any other analysis program. Each star is associated with a file with extension .sys (system); this file contains a few stellar parameters and references to the radial velocity files associated with the star.

Each star can be associated with multiple radial velocity files with extension .vels (velocities). The header of .vels files contain some information about the telescope and instrument that were used to gather the data, and a reference to the paper where the RV tables were published. The rest of the .vels files is a whitespace-separated file containing at least three columns: time of observation in JD, RV measurement in m/s and uncertainty on the RV measurement, e.g.:

```
# telescope = 9.2M HOBBY EBERLY TELESCOPE (HET)
# instrument = HRS
# observatory = MCDONALD OBSERVATORY, TEXAS
# reference = WITTENMYER ET AL. 2009 (APJS, 182, 97)
# bibcode = 2009APJS..182...97W
# source = http://exoplanetarchive.ipac.caltech.edu//data/ExoData/0071/0071395/data/UID_0071395_RVC_003.tbl
  2453462.96527            -137.0                           4.1
  2453479.81567            -147.0                           4.4
  2453480.91902            -136.9                           5.7
  ...
```

The meaning of any other additional columns is specified in the .vels file.

## Where does the data come from?
The initial release of the database (01/30/15) contains data originally hosted on the [NASA Exoplanet Archive](http://exoplanetarchive.ipac.caltech.edu), cleaned up and with duplicate datasets removed. Any data added after that date was pulled from published peer-reviewed papers.
