from turtle import Screen
from snake import Snake
from food import Food
from scoreboard import Scoreboard
import time
from welcome_screen import WelcomeScreen

screen = Screen()
screen.setup(width=600, height=600)
screen.bgcolor("black")
screen.title("My Snake Game")
screen.tracer(0)


while 1 == 1:
    welcome = WelcomeScreen()
    game_started = False

    def start_game():
        global game_started
        welcome.clear()  # remove welcome message
        game_started = True

    screen.listen()
    screen.onkey(start_game, "space")

    # Wait until SPACE is pressed
    while not game_started:
        screen.update()


    snake = Snake()
    food = Food()
    scoreboard = Scoreboard()
    game_is_on = True



    def restart_game():
        scoreboard.reset()
        snake.reset()
        food.refresh()


    welcome_again = ""
    def finish_game():
        global game_is_on
        scoreboard.clear_all_text()
        snake.clear_snake()
        food.clear()
        game_is_on = False



    screen.listen()
    screen.onkey(snake.up, "Up")
    screen.onkey(snake.down, "Down")
    screen.onkey(snake.left, "Left")
    screen.onkey(snake.right, "Right")
    screen.onkey(None, "y")
    screen.onkey(None, "n")


    while game_is_on:
        screen.update()
        time.sleep(0.1)
        snake.move()

        if not game_is_on:
            break  # Immediately exit the loop after setting game_is_on = False

        #Detect collision with food.
        if snake.head.distance(food) < 15:
            food.refresh()
            snake.extend()
            scoreboard.increase_score()

        #Detect collision with wall.
        if snake.head.xcor() > 280 or snake.head.xcor() < -280 or snake.head.ycor() > 280 or snake.head.ycor() < -280:
            scoreboard.reset()
            scoreboard.game_over()
            screen.onkey(restart_game, "y")
            screen.onkey(finish_game, "n")
            snake.clear_snake()
            food.clear()


        #Detect collision with tail.
        for segment in snake.segments:
            if segment == snake.head:
                pass
            elif snake.head.distance(segment) < 10:
                scoreboard.reset()
                scoreboard.game_over()
                screen.onkey(restart_game, "y")
                screen.onkey(finish_game, "n")
                snake.clear_snake()
                food.clear()








