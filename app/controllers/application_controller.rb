# frozen_string_literal: true

# Application controller
class ApplicationController < ActionController::Base
  require 'will_paginate/array'
  helper_method :seconds_to_hms, :seconds_to_ms, :pause_code

  def seconds_to_hms(seconds)
    return '00:00:00' if seconds.nil?

    [seconds / 3600, seconds / 60 % 60, seconds % 60].map { |t| t.to_s.rjust(2, '0') }.join(':')
  end

  def seconds_to_ms(seconds)
    return '00:00' if seconds.nil?

    [seconds / 60, seconds % 60].map { |t| t.to_s.rjust(2, '0') }.join(':')
  end

  def pause_code(pc)
    @pause_codes = {
      'ED' => 'Обучение',
      'PP' => 'Плановый перерыв',
      'VD' => 'Внесение данных',
      'LOGIN' => 'Вход в систему',
      'O' => 'Обед',
      'PRECAL' => 'Раб. перед вызовом',
      'LAGGED' => 'Зависшее сост.'
    }
    @pause_codes[pc]
  end




  private

  def after_sign_in_path_for(user)
    if user.role_key == 'super'
      users_path
    else
      edit_user_path(user)
    end
  end

end
