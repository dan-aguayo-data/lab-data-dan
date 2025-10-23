from turtle import Turtle
ALIGNMENT = "center"
FONT = ("Courier", 24, "normal")


class Scoreboard(Turtle):

    def __init__(self):
        super().__init__()
        self.score = 0
        self.high_score = 0
        self.color("white")
        self.penup()
        self.goto(0, 270)
        self.hideturtle()
        self.update_scoreboard()
        self.continue_game = "DO YOU WANT TO CONTINUE? Y/N"

    def update_scoreboard(self):
        self.clear()
        self.goto(0, 270)
        self.write(f"Score: {self.score} High Score: {self.high_score}", align=ALIGNMENT, font=FONT)

    def reset(self):
        if self.score > self.high_score:
            self.high_score = self.score
        self.goto(0, 270)
        self.score = 0
        self.update_scoreboard()

    def game_over(self):
        self.goto(0, 0)
        self.write("GAME OVER", align=ALIGNMENT, font=FONT)
        self.goto(0, -40)
        self.write(self.continue_game, align=ALIGNMENT, font=FONT)


    def continue_playing(self):
        self.goto(0, 0)
        self.write("GAME OVER", align=ALIGNMENT, font=FONT)

    def increase_score(self):
        self.goto(0, 270)
        self.score += 1
        self.clear()
        self.update_scoreboard()

    def main_screen_scoreboard(self):
        self.clear()

    def clear_all_text(self, reset_score=True):
        self.clear()
        self.goto(0, 270)
        if reset_score:
            self.score = 0