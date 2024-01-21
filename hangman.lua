--[[
Simple hangman game that makes use of coroutines.
@author Scott M.
]]

-- same as string.find but returns true/false if pattern exists or not
local oldStringHas = string.has
string.has = function(s, pattern, init, plain)
    local output = string.find(s, pattern, init, plain)

    return output ~= nil
end

-- iterator for each character in a string
local function each_char(str)
    local function iter(s, i)
        if i <= string.len(s) then
            local letter = string.sub(s, i, i)
            return i + 1, letter
        end
    end

    return iter, str, 1
end

local function print_word(word, letters)
    local output = ''

    for _, char in each_char(word) do
        output = output .. (letters[char] and char or '_')
    end

    print(output)
end

local function print_lives(lives)
    local output = string.format([[
         ____
         |  |
         |  %s
         | %s%s%s
         | %s %s
         |
        ###
    ]],
    lives < 6 and 'O' or ' ',
    lives < 4 and '/' or ' ',
    lives < 5 and '|' or ' ',
    lives < 3 and '\\' or ' ',
    lives < 2 and '/' or ' ',
    lives < 1 and '\\' or ' ')
    
    print(output)
end

local function check_win(word, letters)
    local has_won = true

    for _, char in each_char(word) do
        if not letters[char] then
            has_won = false
            break
        end
    end

    return has_won
end

-- returns true/false if guess does not lose a life
local function guess_letter(word, letter, guessed)
    local safe_guess = true

    if guessed[letter] == true then
        print('You already guessed \'' .. letter .. '\'')
    else
        guessed[letter] = true

        if not string.has(word, letter) then
            print('\'' .. letter .. '\' was not in the word.')
            safe_guess = false
        end
    end

    return safe_guess
end

-- coroutine yields user first character of user input, with a custom prompt
local function input_producer(prompt)
    return coroutine.create(function()
        while true do
            print(prompt or 'Enter a letter:')
            local letter = string.sub(io.read(), 1, 1)

            coroutine.yield(letter)
        end
    end)
end

-- determines if character is letter, and normalizes characters to lowercase
local function valid_letter_filter(co_producer)
    return coroutine.create(function()
        while true do
            local is_successful, letter = coroutine.resume(co_producer)

            local is_valid = string.has(letter, "%a")

            if is_valid then
                letter = string.lower(letter)
            end

            coroutine.yield(is_valid, letter)
        end
    end)
end

-- orchestrates the game loop of hangman, using coroutines to get user input
local function hangman_consumer(co_producer, word)
    local guessed = {}
    local lives = 6

    while lives > 0 do
        print_word(word, guessed)
        print_lives(lives)
        local is_successful, is_valid, letter = coroutine.resume(co_producer)

        if is_valid then
            -- an 'unsafe guess' loses a life, i.e., guessing a wrong letter for the first time
            local safe_guess = guess_letter(word, letter, guessed)

            if not safe_guess then lives = lives - 1 end

            if check_win(word, guessed) then return true end
        else
            print('Invalid letter, try again.')
        end
        print()
    end

    return false
end

local function play_hangman(word)
    print('Lua Hangman by Scott Meadows')

    local input = input_producer('Enter a letter:')
    local is_won = hangman_consumer(valid_letter_filter(input), word)

    if is_won then
        print('The word was ' .. word .. '. You win!')
    else
        print_lives(0)
        print('You are out of guesses. The word was ' .. word .. '.')
    end
end

--[[
play_hangman('lua')
--]]

-- revert overwritten fields
string.has = oldStringHas

return play_hangman