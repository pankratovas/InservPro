import Flatpickr from "stimulus-flatpickr"

export default class extends Flatpickr {
    initialize() {
        let Russian = {
            weekdays: {
                shorthand: ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"],
                longhand: [
                    "Воскресенье",
                    "Понедельник",
                    "Вторник",
                    "Среда",
                    "Четверг",
                    "Пятница",
                    "Суббота",
                ],
            },
            months: {
                shorthand: [
                    "Янв",
                    "Фев",
                    "Март",
                    "Апр",
                    "Май",
                    "Июнь",
                    "Июль",
                    "Авг",
                    "Сен",
                    "Окт",
                    "Ноя",
                    "Дек",
                ],
                longhand: [
                    "Январь",
                    "Февраль",
                    "Март",
                    "Апрель",
                    "Май",
                    "Июнь",
                    "Июль",
                    "Август",
                    "Сентябрь",
                    "Октябрь",
                    "Ноябрь",
                    "Декабрь",
                ],
            },
            firstDayOfWeek: 1,
            ordinal: function () {
                return "";
            },
            rangeSeparator: " — ",
            weekAbbreviation: "Нед.",
            scrollTitle: "Прокрутите для увеличения",
            toggleTitle: "Нажмите для переключения",
            amPM: ["ДП", "ПП"],
            yearAriaLabel: "Год",
            time_24hr: true,
        };
        this.config = {
            locale: Russian,
            enableTime: true,
            enableSeconds: true
        }
    }
}