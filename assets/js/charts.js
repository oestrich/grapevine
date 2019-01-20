import Chart from "chart.js";

document.querySelectorAll(".chart").forEach(chartElement => {
  let ctx = chartElement.querySelector("canvas").getContext('2d');

  fetch(chartElement.dataset.url).then(response => {
    return response.json();
  }).then(data => {
    data.statistics.sort((a, b) => {
      return a.time < b.time;
    })

    let labels = data.statistics.map(stat => {
      return stat.time;
    });
    let values = data.statistics.map(stat => {
      return stat.count;
    });

    let chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: labels,
        datasets: [{
          label: "Number of Players Online",
          data: values,
          fill: true,
          lineTension: 0.3,
          borderColor: "#00FF00",
          backgroundColor: "rgba(0, 255, 0, 0.5)",
          pointBackgroundColor: "#00FF00",
          borderWidth: 2,
          pointHoverBackgroundColor: "#00FF00",
          pointRadius: 0,
          pointHitRadius: 8
        }]
      },
      options: {
        maintainAspectRatio: false,
        animation: false,
        legend: { display: false },
        scales: {
          yAxes: [{
            ticks: {
              maxTicksLimit: 4,
              min: 0,
              suggestedMax: 5,
              callback: function (value) { if (Number.isInteger(value)) { return value; } },
              fontColor: "#BBB",
            },
            scaleLabel: { fontSize: 16, fontColor: "#BBB", display: true, labelString: "Concurrent Players" }
          }],
          xAxes: [{
            gridLines: { drawOnChartArea: false },
            ticks: { fontColor: "#BBB" },
            time: {
              displayFormats: { hour: "MMM D, h a" },
              unit: "hour",
              tooltipFormat: "MMM D, YYYY h a"
            },
            type: "time"
          }]
        }
      }
    });
  });
});
