require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

db = SQLite3::Database.new('db/db.db')
db.results_as_hash = true

# Creates a user by taking username and password from the form, encrypts password and inserts them into the users table
def create()
    db = SQLite3::Database.new('db/db.db')
    db.results_as_hash = true
    name = params["name"]
    password = BCrypt::Password.create(params["pass"])
    db.execute('INSERT INTO users(Username, Password) VALUES(?, ?)', name, password) 
    redirect('/')
end

# Checks if there is a username entered, if the username has a match in the database and if the correct password was entered
def login()
    db = SQLite3::Database.new('db/db.db')
    result = db.execute("SELECT Password FROM users WHERE Username =(?)", params["name"])
    if result[0] == nil
        session[:loginfail] = true
        redirect('/')
    end
    not_password = result[0][0]
    if BCrypt::Password.new(not_password) == params["pass"]
        session[:loggedin] = true
        session[:user] = params["name"]
        redirect('/')
    else
        session[:loginfail] = true
        redirect('/')
    end
end

# Creates a thread by taking title, description from the form, userid from the session and users table and inserts that into the threads table
def new_thread()
    db = SQLite3::Database.new('db/db.db')
    opid = db.execute("SELECT UserId FROM users WHERE Username=(?)", session[:user])
    if opid != nil
        db.execute("INSERT INTO threads(Title, Description, OpId) VALUES(?, ?, ?)", params["title"], params["description"], opid)
    else
        redirect('/')
    end
    redirect('/')
end

# Takes the text for threads and replies from the database and puts them into the locals dictionary so they can be displayed on the site
def index()
    db = SQLite3::Database.new('db/db.db')
    db.results_as_hash = true
    threads = db.execute("SELECT threads.*, users.Username FROM threads INNER JOIN users ON threads.OpId = users.UserId")
    replies = db.execute("SELECT replies.*, users.Username FROM replies INNER JOIN users ON replies.AuthorId = users.UserId")
    slim(:index, locals:{threads: threads, replies: replies})
end

# Takes text from the form and inserts into the replies table. Also takes id of the thread it was posted in and id of the user who posted the reply
def reply()
    db = SQLite3::Database.new('db/db.db')
    authorid = db.execute("SELECT UserId FROM users WHERE Username=(?)", session[:user])
    if authorid != nil
        db.execute("INSERT INTO replies(Text, AuthorId, ParentId) VALUES(?, ?, ?)", params["reply"], authorid, params["threadId"])
    else
        redirect('/')
    end
    redirect('/')
end

def delete_thread()
    db = SQLite3::Database.new('db/db.db')
end

def registerfunc()
    db = SQLite3::Database.new('db/db.db')
    db.results_as_hash = true
    uname = params["reg_username"]
    pword = BCrypt::Password.create(params["reg_password"])
    begin
        db.execute('INSERT INTO users(Username, Password) VALUES(?, ?)', uname, pword)
    rescue
        session[:reg_error] = true
        redirect('/register')
    end
    redirect('/login')
end

def loginfunc()
    db = SQLite3::Database.new('db/db.db')
    db.results_as_hash = true

    loginuname = params["log_username"]
    loginpword = params["log_password"]

    begin
        existance_check_name = db.execute("SELECT Username FROM users WHERE Username =(?)", params["log_username"])
        existance_check_pass = db.execute("SELECT Password FROM users WHERE Username  =(?)", params["log_username"])

        if BCrypt::Password.new(existance_check_pass[0][0]) != loginpword
            session[:log_error] = "Password error, the password was not correct :/"
            redirect('/login')
        else
            session[:loggedin_user] = existance_check_name[0][0]
            redirect('/courses')
        end
    rescue
        session[:log_error] = "Username error, this username does not exist. Please check your spelling or make an account"
        redirect('/login')
    end
end