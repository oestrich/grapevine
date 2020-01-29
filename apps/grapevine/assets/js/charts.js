import Chart from "chart.js";
import moment from "moment";

document.querySelectorAll(".chart[data-type='48-hours']").forEach(chartElement => {
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
          borderColor: "#aa74da",
          backgroundColor: "hsla(272, 58%, 65%, 1)",
          pointBackgroundColor: "#aa74da",
          borderWidth: 2,
          pointHoverBackgroundColor: "#aa74da",
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

document.querySelectorAll(".chart[data-type='week']").forEach(chartElement => {
  let ctx = chartElement.querySelector("canvas").getContext('2d');

  let url = new URL(chartElement.dataset.url, window.location.href);
  let statistics = {};

  let json = ["avg", "max", "min"].map((type) => {
    url.searchParams.set("type", type);

    return fetch(url.toString()).then(response => {
      return response.json();
    }).then(json => {
      json.type = type;
      return json;
    });
  });

  Promise.all(json).then((values) => {
    values.map(value => {
      statistics[value.type] = value.statistics.sort((a, b) => {
        return a.time < b.time;
      })
    });
  }).then(() => {
    let labels = statistics.avg.map(stat => {
      return stat.time;
    });

    let avgValues = statistics.avg.map(stat => {
      if (stat.count) {
        return Math.round(stat.count);
      }
    });
    let maxValues = statistics.max.map(stat => {
      return stat.count;
    });
    let minValues = statistics.min.map(stat => {
      return stat.count;
    });

    let chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Minimum",
            data: minValues,
            fill: true,
            lineTension: 0.3,
            borderColor: "#aa74da",
            backgroundColor: "hsla(268, 58%, 46%, 1)",
            pointBackgroundColor: "#aa74da",
            borderWidth: 1,
            pointHoverBackgroundColor: "#aa74da",
            pointRadius: 0,
            pointHitRadius: 8
          },
          {
            label: "Average",
            data: avgValues,
            fill: true,
            lineTension: 0.3,
            borderColor: "#aa74da",
            backgroundColor: "hsla(272, 58%, 65%, 1)",
            pointBackgroundColor: "#aa74da",
            borderWidth: 3,
            pointHoverBackgroundColor: "#aa74da",
            pointRadius: 0,
            pointHitRadius: 8
          },
          {
            label: "Maximum",
            data: maxValues,
            fill: true,
            lineTension: 0.3,
            borderColor: "#aa74da",
            backgroundColor: "hsla(280, 70%, 84%, 1)",
            pointBackgroundColor: "#aa74da",
            borderWidth: 1,
            pointHoverBackgroundColor: "#aa74da",
            pointRadius: 0,
            pointHitRadius: 8
          }
        ]
      },
      options: {
        maintainAspectRatio: false,
        animation: false,
        legend: { display: false },
        tooltips: { mode: 'index' },
        scales: {
          yAxes: [{
            ticks: {
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

document.querySelectorAll(".chart[data-type='tod']").forEach(chartElement => {
  let ctx = chartElement.querySelector("canvas").getContext('2d');

  let url = new URL(chartElement.dataset.url, window.location.href);
  let statistics = {};

  let json = ["avg", "max", "min"].map((type) => {
    url.searchParams.set("type", type);

    return fetch(url.toString()).then(response => {
      return response.json();
    }).then(json => {
      json.type = type;
      return json;
    });
  });

  Promise.all(json).then((values) => {
    values.map(value => {
      statistics[value.type] = value.statistics.sort((a, b) => {
        return a.time < b.time;
      })
    });
  }).then(() => {
    let offset = (new Date()).getTimezoneOffset();

    let hourTweleve = (hour, period) => {
      if (hour == 0) {
        return `12 ${period}`;
      } else {
        return `${hour} ${period}`;
      }
    }

    let hourFormat = (hour) => {
      hour = hour.getHours();

      if (hour >= 12) {
        return hourTweleve(hour % 12, "PM");
      } else {
        return hourTweleve(hour, "AM");
      }
    }

    let labels = statistics.avg.map(stat => {
      let hour = moment().
        utcOffset(0).
        set({hour: stat.hour});

      return hourFormat(hour._d);
    });

    let avgValues = statistics.avg.map(stat => {
      return Math.round(stat.count);
    });
    let maxValues = statistics.max.map(stat => {
      return stat.count;
    });
    let minValues = statistics.min.map(stat => {
      return stat.count;
    });

    let chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Minimum",
            data: minValues,
            fill: true,
            lineTension: 0.3,
            borderColor: "#aa74da",
            backgroundColor: "hsla(268, 58%, 46%, 1)",
            pointBackgroundColor: "#aa74da",
            borderWidth: 1,
            pointHoverBackgroundColor: "#aa74da",
            pointRadius: 0,
            pointHitRadius: 8
          },
          {
            label: "Average",
            data: avgValues,
            fill: true,
            lineTension: 0.3,
            borderColor: "#aa74da",
            backgroundColor: "hsla(272, 58%, 65%, 1)",
            pointBackgroundColor: "#aa74da",
            borderWidth: 3,
            pointHoverBackgroundColor: "#aa74da",
            pointRadius: 0,
            pointHitRadius: 8
          },
          {
            label: "Maximum",
            data: maxValues,
            fill: true,
            lineTension: 0.3,
            borderColor: "#aa74da",
            backgroundColor: "hsla(280, 70%, 84%, 1)",
            pointBackgroundColor: "#aa74da",
            borderWidth: 1,
            pointHoverBackgroundColor: "#aa74da",
            pointRadius: 0,
            pointHitRadius: 8
          }
        ]
      },
      options: {
        maintainAspectRatio: false,
        animation: false,
        legend: { display: false },
        tooltips: { mode: 'index' },
        scales: {
          yAxes: [{
            ticks: {
              min: 0,
              suggestedMax: 5,
              callback: function (value) { if (Number.isInteger(value)) { return value; } },
              fontColor: "#BBB",
            },
            scaleLabel: { fontSize: 16, fontColor: "#BBB", display: true, labelString: "Concurrent Players" }
          }],
          xAxes: [{
            stacked: true,
            gridLines: { drawOnChartArea: false },
            ticks: { fontColor: "#BBB" },
          }]
        }
      }
    });
  });
});
