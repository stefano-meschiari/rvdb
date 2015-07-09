function starClick(obj) {
    Shiny.unbindAll();
    $("#star").val($(obj).html());
    $("#tabs li:nth-of-type(2) a").click();
    Shiny.bindAll();
}

function externalDb(url) {
    window.open(url + encodeURIComponent($("#star").val()), "_blank");
}

function nexsci() {
    externalDb("http://exoplanetarchive.ipac.caltech.edu/cgi-bin/DisplayOverview/nph-DisplayOverview?objname=");
}

function simbad() {
    externalDb("http://simbad.u-strasbg.fr/simbad/sim-basic?submit=SIMBAD+search&Ident=");
}

function exoplanetsorg() {
    alert("Not implemented yet.");
}
