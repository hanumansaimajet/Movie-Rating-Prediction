
# Movie Rating Prediction

In this project our plan is to develop a model that can predict how a 
user will rate a specific movie, similar to a movie recommendation 
system. Our model will make predictions based on user ratings of 
other movies and the average rating of the specific movie.




## Data sets Used
For this project we using “MovieLens dataset”


 - [MovieLens 10M dataset](https://grouplens.org/datasets/movielens/10m/)
 - [MovieLens 10M dataset - zip file](https://files.grouplens.org/datasets/movielens/ml-10m.zip)



## DATA DESCRIPTION

The dataset presents information about 10 million movie ratings 
including user id, movie id, user rating of the movie (between 0.5 to 
5 stars), timestamp of the rating (seconds since midnight 
Coordinated Universal Time of January 1, 1970), title of the movie, 
and movie genre(s): Action, Adventure, Animation, Children’s, 
Comedy, Crime, Documentary, Drama, Fantasy, Film-Noir, Horror, 
IMAX, Musical, Mystery, Romance, Sci-Fi, Thriller, War, and/or 
Western

It contains 10M rows and 6 coloumns. Since data is huge we are 
dividing into training and validation sets earlier than later stages.
## Methodology
After downloading and unzipping the data file, I will extract its 
contents and place the data in a data frame.
Next, I will split the data into two sets: a training set and a validation 
set. The training set will contain 90% of the data (9 million ratings) 
which the model will learn from. The validation set will contain the 
remaining 10% of data (1 million ratings) which will be used to 
evaluate the performance of our model
First, we will run an exploratory data analysis to get a general 
overview of the data and explore possible predictor variables.
Then, we will include the most important features into numerous 
models i..e We are planning to test three different regression 
models to predict each rating .Then, we will select the best model 
and apply it to the test data set (validation)
Finally, We will deploy the model with the smallest error to the test 
set and evaluate the results.
## Model Development

we will test three different regression models to predict each rating in the training set . Then, I will select the best model and apply it to the test set .
  - Model 1 :  Predicted Rating = Global Average Rating + Movie Effect
  - Model 2 : Predicted Rating = Global Average Rating + User Effect
  - Model 3 : Predicted Rating = Global Average Rating + Movie Effect + User Effect
  The global average rating is the average rating across all entries in the dataset. 
The movie effect is the difference between the average rating for the specific movie and the global average rating.
Similarly, the user effect is the difference between the average rating for the specific user and the global average rating.   To evaluate three models we will use  RMSE(Root Mean Square Error).
