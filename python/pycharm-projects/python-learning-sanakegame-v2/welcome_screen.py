
from turtle import Turtle

ALIGNMENT = "center"
FONT = ("Courier", 20, "bold")

class WelcomeScreen(Turtle):
    def __init__(self):
        super().__init__()
        self.hideturtle()
        self.color("white")
        self.penup()
        self.goto(0, 100)
        self.show_welcome_message()

    def show_welcome_message(self):
        self.write("WELCOME TO SNAKE GAME", align=ALIGNMENT, font=FONT)
        self.goto(0, 40)
        self.write("PRESS 'SPACE' TO START", align=ALIGNMENT, font=("Courier", 16, "normal"))
