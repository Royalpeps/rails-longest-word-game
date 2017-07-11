class PagesController < ApplicationController
  def game
    @grid = generate_grid(10)
    n_of_attempt
  end

  def score
    @guess = params[:guess]
    @start_time = params[:start_time].to_i
    @grid = params[:grid].split('')
    @end_time = Time.now.to_i
    @result = run_game(@guess, @grid, @start_time, @end_time)
  end

  private

  def n_of_attempt
    if session[:n_of_attempt]
      session[:n_of_attempt] += 1
    else
      session[:n_of_attempt] =1
    end
  end

  def generate_grid(grid_size)
    @grid = Array.new(grid_size) { ('A'..'Z').to_a[rand(26)] }
  end

  def included?(guess, grid)
    guess.split('').all? { |letter| guess.split('').count(letter) <= grid.count(letter) }
  end

  def compute_score(attempt, time_taken)
    time_taken > 60.0 ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: (end_time - start_time).to_i }

    result[:translation] = get_translation(attempt)
    result[:score], result[:message] = score_and_message(
      attempt, result[:translation], grid, result[:time]
    )
    result
  end

  def score_and_message(attempt, translation, grid, time)
    if included?(attempt.upcase, grid)
      if translation
        score = compute_score(attempt, time)
        [score, 'well done']
      else
        [0, 'not an english word']
      end
    else
      [0, 'not in the grid']
    end
  end

  def get_translation(word)
    api_key = '3c1a382c-74d0-47c4-9f97-a62c59ce3ca0'
    begin
      response = open("https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=#{api_key}&input=#{word}")
      json = JSON.parse(response.read.to_s)
      if json['outputs'] && json['outputs'][0] && json['outputs'][0]['output'] && json['outputs'][0]['output'] != word
        return json['outputs'][0]['output']
      end
    rescue
      if File.read('/usr/share/dict/words').upcase.split("\n").include? word.upcase
        return word
      else
        return nil
      end
    end
  end
end
