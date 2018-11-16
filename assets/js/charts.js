import Chartkick from "chartkick";
import Chart from "chart.js";

Chartkick.addAdapter(Chart);

document.querySelectorAll(".chart").forEach(chart => {
  new Chartkick.AreaChart(chart.id, chart.dataset.url, {points: false, label: "Players"});
});
