ROLES = Role.create([
                      { name: 'Администратор',
                        permissions:
                          { role: 'super',
                            campaigns: [],
                            ingroups: [],
                            reports: []
                          },
                       description: 'Пользователи с этой ролью имеют доступ к меню Управление, могут добавлять, изменять, удалять другие роли и пользователей.' }
                    ])
USERS = User.create([
                      { first_name: 'Администратор', middle_name: '', last_name: 'Инсерв', sip_number: '2000',
                        role_id: 1, activated: true, email: 'admin@in-serv.ru', password: '123456',
                        password_confirmation: '123456' }
                    ])
REPORTS = Report.create([
                          { id: 100, name: 'realtime_report', description: 'Вызовы в реальном времени', activated: true },
                          { id: 1, name: 'inbound_calls', description: 'Входящие вызовы', activated: true },
                          { id: 2, name: 'outbound_calls', description: 'Исходящие вызовы', activated: true },
                          { id: 3, name: 'summary_calls', description: 'Общая статистика', activated: true },
                          { id: 4, name: 'summary_calls_24', description: 'Общая статистика за сутки', activated: true },
                          { id: 5, name: 'operators_detailed', description: 'Детальный по операторам', activated: true },
                          { id: 6, name: 'calls_by_day', description: 'Вызовы за день', activated: true },
                          { id: 7, name: 'statuses_by_user', description: 'Статусы по операторам', activated: true },
                          { id: 8, name: 'calls_by_interval', description: 'Вызовы с разбивкой по интервалам', activated: true },
                          { id: 9, name: 'operator_by_period', description: 'По оператору за период', activated: true },
                          { id: 10, name: 'operators_by_periods', description: 'По операторам за период', activated: true },
                          { id: 11, name: 'calls_by_hour', description: 'Вызовы по часам', activated: true },
                          { id: 12, name: 'call_center_24', description: 'Колл-центр за сутки', activated: true },
                          { id: 13, name: 'operators_skills', description: 'Навыки операторов', activated: true },
                          { id: 14, name: 'calls_by_regions', description: 'Вызовы по регионам', activated: true },
                          { id: 15, name: 'statuses_by_regions', description: 'Статусы по регионам', activated: true } ])