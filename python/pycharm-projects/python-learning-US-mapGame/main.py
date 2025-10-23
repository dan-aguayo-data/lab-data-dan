import turtle
import pandas

IMAGE = "blank_states_img.gif"

screen = turtle.Screen()
screen.title("U.S. States Game")
screen.addshape(IMAGE)
turtle.shape(IMAGE)


df_states = pandas.read_csv("50_states.csv")

all_states = df_states.state.to_list()


while all_states:
    answer_state = screen.textinput(title="Guess the State", prompt="What's another State's name?")
    if answer_state == "Exit":
        missing_states = pandas.DataFrame(all_states)
        missing_states.to_csv("missing_states.csv")
        break
    if answer_state in all_states:
        t = turtle.Turtle()
        t.hideturtle()
        t.penup()
        state_data = df_states[df_states.state == answer_state]  #row of data
        t.goto(state_data.x.item(), state_data.y.item()) #tap into attributes
        t.write(state_data.state.item())
        all_states.remove(state_data.state.item())




#HOW WE GOT COORDINATES

# def get_mouse_click_coor(x,y):
#     print(x,y)
#
#
# turtle.onscreenclick(get_mouse_click_coor)
#
# turtle.mainloop()