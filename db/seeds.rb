ROLES = Role.create([
                      {name: "Администратор",
                       permissions: {
                         role: 'super',
                         campaigns: [],
                         ingroups: [],
                         reports: []
                       },
                       description: ""}
                    ])
USERS = User.create([
                      {first_name: "Администратор",middle_name: "", last_name:"Инсерв", sip_number: "2000", role_id: 1,
                       activated: true, email:"admin@in-serv.ru", password:'123456', password_confirmation: '123456'}
                    ])
REPORTS = Report.create([
                          {id: 100, name: "realtime_report", description: "Отчет реального времени", activated: true},
                          {id: 1, name: "inbound_calls", description: "Входящие вызовы", activated: true},
                          {id: 2, name: "outbound_calls", description: "Исходящие вызовы", activated: true},
                          {id: 3, name: "summary_calls", description: "Общая статистика вызовов", activated: true},
                          {id: 4, name: "summary_calls_preset", description: "Быстрая общая статистика вызовов", activated: true},
                          {id: 5, name: "agent_detailed", description: "Детальная по операторам", activated: true},
                          {id: 6, name: "yesterday_report", description: "Статистика за день", activated: true},
                          {id: 7, name: "statuses_by_user", description: "Статусы по операторам", activated: true},
                          {id: 8, name: "calls_by_interval", description: "Вызовы с разбивкой по интервалам", activated: true},
                          {id: 9, name: "operator_statistics", description: "Статистика по оператору за период", activated: true},
                          {id: 10, name: "all_operator_statistics", description: "Сводная статистика по операторам", activated: true},
                          {id: 11, name: "calls_by_hour", description: "Почасовой отчет по вызовам за день", activated: true},
                          {id: 12, name: "cc_daily", description: "Отчет по КЦ за сутки", activated: true},
                          {id: 13, name: "agent_skills", description: "Навыки операторов", activated: true},
                          {id: 14, name: "calls_by_regions", description: "Вызовы по регионам", activated: true},
                          {id: 15, name: "statuses_by_regions", description: "Статусы по регионам", activated: true}
                        ])