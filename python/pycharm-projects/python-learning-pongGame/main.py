import time
from turtle import Screen, Turtle
from paddle import Paddle
from ball import Ball
from scoreboard import Scoreboard

# Setup screen
screen = Screen()
screen.bgcolor("black")
screen.setup(width=800, height=600)
screen.title("Pong")
screen.tracer(0)

# Initialize game objects
l_paddle = Paddle((-350, 0))
r_paddle = Paddle((350, 0))
ball = Ball()
scoreboard = Scoreboard()

# Display instructions
message = Turtle()
message.color("white")
message.hideturtle()
message.penup()
message.goto(0, 0)
message.write("Press SPACE to start/pause the game\nPress Q to reset", align="center", font=("Courier", 16, "normal"))

# Game state flags
paused = True
game_is_on = True

# Control functions
def toggle_pause():
    global paused
    paused = not paused
    if not paused:
        message.clear()
        game_loop()
    else:
        message.clear()
        message.write("Paused\nPress SPACE to resume", align="center", font=("Courier", 16, "normal"))

def reset_game():
    global paused
    # Reset all components
    ball.reset_position()
    scoreboard.reset_scores()
    l_paddle.goto(-350, 0)
    r_paddle.goto(350, 0)
    paused = True
    message.clear()
    message.goto(0, 0)
    message.write("Game Reset\nPress SPACE to start", align="center", font=("Courier", 16, "normal"))

# Key bindings
screen.listen()
screen.onkey(r_paddle.go_up, "Up")
screen.onkey(r_paddle.go_down, "Down")
screen.onkey(l_paddle.go_up, "w")
screen.onkey(l_paddle.go_down, "s")
screen.onkey(toggle_pause, "space")
screen.onkey(reset_game, "q")

# Game loop using ontimer
def game_loop():
    if game_is_on and not paused:
        ball.move()

        # Wall collision
        if ball.ycor() > 280 or ball.ycor() < -280:
            ball.bounce_y()

        # Paddle collision
        if (ball.distance(r_paddle) < 50 and ball.xcor() > 320) or \
           (ball.distance(l_paddle) < 50 and ball.xcor() < -320):
            ball.bounce_x()

        # Right miss
        if ball.xcor() > 380:
            time.sleep(0.2)
            ball.reset_position()
            scoreboard.l_point()

        # Left miss
        if ball.xcor() < -380:
            time.sleep(0.5)
            ball.reset_position()
            scoreboard.r_point()

        screen.update()
        screen.ontimer(game_loop, int(ball.move_speed * 1000))  # Schedule next loop

screen.mainloop()
