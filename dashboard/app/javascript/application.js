// Entry point for the build script in your package.json
import "./controllers";
import "chartkick";
import "Chart.bundle";
import "chartkick/chart.js";

//= require Chart.
//= require chartkick
//= require Chart.bundle



const feather = require("feather-icons");
document.addEventListener("turbolinks:load", function() {
    feather.replace();
})