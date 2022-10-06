import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        const dynamicPart = document.getElementById("realtime_queue");
        setInterval(function() {
            const xmlhttp = new XMLHttpRequest();
            xmlhttp.open('GET', "100/realtime_statistics")
            xmlhttp.send();
            xmlhttp.onload = function() {
                dynamicPart.innerHTML = xmlhttp.responseText;
            };
        }, 3000);
    }

}