from turtle import Screen,Turtle

screen = Screen()
screen.setup(width=600,height=600)
screen.bgcolor("black")
screen.title("My snake game")

for n in range(3):
    name = f'segment_{n+1}'
    name = Turtle(shape="square")
    name.color("white")
    name.goto(n*-20,0)



screen.exitonclick()