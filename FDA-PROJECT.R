---
title: "MovieLens Rating Prediction"
author: "HANUMAN SAI 19BPS1066 | Vijay Gopu 19BPS1078"
date: "12/12/2021"
output: html_document
        
---

#First of all we load the data from corresponding link.
```{r}

library(dplyr)
library(tidyverse)
library(caret)
dl <- tempfile()
download.file("http://files.grouplens.org/datasets/movielens/ml-10m.zip", dl)
```
# Dataset is built by
```{r}
ratings <- read.table(text = gsub("::", "\t", readLines(unzip(dl, "ml-10M100K/ratings.dat"))),col.names = c("userId", "movieId", "rating", "timestamp"))
movies <- str_split_fixed(readLines(unzip(dl, "ml-10M100K/movies.dat")), "\\::", 3)
colnames(movies) <- c("movieId", "title", "genres")
movies <- as.data.frame(movies) %>% mutate(title = as.character(title),genres = as.character(genres))
movies$movieId<- as.integer(movies$movieId)
movielens <- left_join(ratings, movies, by = "movieId")
movielens
```

### Split Raw Data: Train and Test Sets
#We now create a validation set of 10% of Movielens data and 90% set for training
#Training dataset used for building the algorithm and the validation set used for testing. 

```{r}
set.seed(1)
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
train <- movielens[-test_index,]
test <- movielens[test_index,]

##We make sure userId and movieId in validation set are also in train set:
validation <- test %>% semi_join(train, by = "movieId") %>% semi_join(train, by = "userId")

##and finnally we add the rows removed from validation set back into train set:
removed <- anti_join(test, validation)
train <- rbind(train, removed)
##we remove unneeded 
rm(dl, ratings, movies, test_index, test, movielens, removed)
train
validation



```
##Data Exploration & Visualization
#Before we start building the model, we need to get  familiar and understand  the data structure in order to build better model.



```{r}
head(train)
```

```{r}
summary(train)
```

```{r}
#No.of unique movies and users 
train %>% summarize(n_users=n_distinct(userId),n_movies=n_distinct(movieId))
```

#Next we going to check if dataset contains any missing values
```{r}
any(is.na(train))
```
There are no missing values in the dataset.

## Exploratory Data Analysis (EDA)
```{r}
summary(train$rating)
```
so ,the average rating across the 9 million ratings  in the training set is 3.51 stars








```{r}
ggplot(train,aes(x=rating)) + geom_bar() + labs(title="Distribution of Ratings",x="Rating",y="No.of Ratings")
```

As you can see, the ratings appear to be left-skewed since there are few ratings between 0 to 2 stars and many ratings between 3 to 5 stars. It is important to note that users only had the option to select whole number or half ratings. Thus, there were only ten options users could select from (0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5). In general, half star ratings appear to be less common than whole star ratings.



##Ratings by movie
```{r}
length(unique(train$movieId))
```

There are 10,667 movies in the training dataset


#Movies with Most Ratings
```{r}
#Movies with most ratings accompained by their average rating
movie_ratings <- train %>% group_by(title) %>% summarize(avg_movie_rating = mean(rating), num_ratings = n()) %>% arrange(desc(num_ratings))
head(movie_ratings)
```

*Pulp Fiction*, *Forrest Gump*, *Silence of the Lambs*, *Jurassic Park*, *Shawshank Redemption*, and *Braveheart* have the most ratings (about 30,000 each) with an average rating ranging between 3.66 and 4.46.
  






#Most common average movie rating
```{r}
ggplot(movie_ratings, aes(x=avg_movie_rating)) + geom_histogram(bins=10) +
    labs(title = "Distribution of Average Movie Ratings", 
         x = "Average Movie Rating", 
         y = "Number of Movies")
```

Based on the histogram above, most movies appear to have an average rating between 2.5 and 4. In addition, there are only be a few movies with an average rating of 0.5 stars (worst possible rating) and 5 stars (perfect rating). 


Do movies with many ratings tend to be rated higher than movies with few ratings?
```{r}
ggplot(movie_ratings,aes(x = avg_movie_rating, y = num_ratings)) + geom_point() + geom_smooth(method = "lm") +
    labs(title = "Average Movie Rating vs Number of Ratings", 
         x = "Average Movie Rating", 
         y = "Number of Ratings")
```
```{r}
cor(movie_ratings$avg_movie_rating, movie_ratings$num_ratings)

```
In general, the more a movie is rated by users, the greater its average rating. However, this relationship is relatively weak. 

Now, we will perform a deeper analysis of ratings by user. Similar to my analysis of ratings by movie, I will compare the average rating of users and determine whether the number of ratings they have given in total impact their average rating.
  


### Ratings by User
```{r}
length(unique(train$userId))
```

There are 69,878 users in the training dataset.


* Users Who Rated the Most Movies
```{r}
# Users who rated the most movies, accompanied by their average rating
user_ratings <- train %>% group_by(userId) %>% summarize(avg_user_rating = mean(rating), num_ratings = n()) %>% arrange(desc(num_ratings)) 

head(user_ratings)
```
The user that rated the most movies rated a total of 6616 movies with an average rating of 3.26.



##Most Common Average Rating Given by Users
```{r}
ggplot(user_ratings, aes(x=avg_user_rating)) + geom_histogram(bins=10) + labs(title = "Distribution of Average User Ratings", x = "Average User Rating", y = "Number of Users")
```
Based on the histogram above, most users give an average rating between 3 and 4.5. In addition, only a few users have a very high or very low average rating (i.e. 0 to 2 stars; 5 stars). 



#Do users who rate many movies tend to rate higher than users who rate few movies?
```{r}
ggplot(user_ratings,aes(x = avg_user_rating, y = num_ratings)) + geom_point() + geom_smooth(method = "lm") + labs(title = "Average User Rating vs Number of Ratings",
         x = "Average User Rating", 
         y = "Number of Ratings")
```

```{r}
cor(user_ratings$avg_user_rating, user_ratings$num_ratings)
```



*Mean movie ratings given by users
```{r}
train %>% group_by(userId) %>% filter(n() >= 100) %>% summarize(b_u = mean(rating)) %>% ggplot(aes(b_u)) + geom_histogram(bins = 30, color = "black") +
  xlab("Mean rating") +
  ylab("Number of users") +
  ggtitle("Mean movie ratings given by users") +
  scale_x_discrete(limits = c(seq(0.5,5,0.5))) +
  theme_light()
```
  We can depict that 3.5 is the highest mean rating given by almost 3000+ users.



### Key Insights
Based on our EDA, we would expect most ratings to be between 3 and 4 stars. In addition, both movie and user averages appear to have an impact on the actual rating, so we will include these features in model development. However, the number of ratings a movie receives and the number of movies a user rates has a small impact on the actual rating. Thus, we will not include either component in model development.

\pagebreak

## Model Development 

### Models
we will test three different regression models to predict each rating in the training set . Then, I will select the best model and apply it to the test set .
  
**Model 1**: Predicted Rating = Global Average Rating + Movie Effect
  
**Model 2**: Predicted Rating = Global Average Rating + User Effect
  
**Model 3**: Predicted Rating = Global Average Rating + Movie Effect + User Effect
  
The global average rating is the average rating across all entries in the dataset. 
The movie effect is the difference between the average rating for the specific movie and the global average rating.
Similarly, the user effect is the difference between the average rating for the specific user and the global average rating

#To evaluate the three models, I will use RMSE (Root Mean Square Error). Ultimately, we will select the model with the lowest RMSE.

### Model Example
For example, suppose I am trying to predict User X's rating of *Forest Gump* and the overall average rating (across all movies/users) is 3 stars, the average rating of Forest Gump is 4 stars, and the average rating User X gives is 2.5 stars.
Thus the global average rating is 3, the movie effect is +1 (4-3), and the user effect is -0.5 (2.5-3).
  
**Model 1**: Predicted Rating = 3 + 1 = 4
  
**Model 2**: Predicted Rating = 3 - 0.5 = 2.5
  
**Model 3**: Predicted Rating = 3 + 1 - 0.5 = 3.5
  
\  
```{r}
RMSE <- function(true_ratings, predicted_ratings){sqrt(mean((true_ratings - predicted_ratings)^2))}
```

```{r}
overall_avg_rating <- mean(train$rating)
overall_avg_rating
```

#The global average rating is 3.512465.

\pagebreak
  
### Model 1: Movie Effect
```{r}
# Calculate difference between each movie’s average rating and the overall average rating
movie_ratings %>% mutate(movie_avg_diff = avg_movie_rating - overall_avg_rating) -> movie_ratings
head(movie_ratings)

```

```{r}
qplot(movie_avg_diff, data = movie_ratings, bins = 10, color = I("black"))+
labs(title = "Distribution of Average Movie Rating and Global Average Differences",
x = "Difference Between Average Movie Rating and Global Average",
y = "Number of Movies")
```
As you can see, a lot of movies have an average rating close to the global average (difference of 0) and few movies have an average rating that is far from the global average (difference of +/- 2). In addition, the average rating for the specific movie is more likely to have a negative impact on each rating since there are more negative differences.

```{r}
model_1_predictions <- overall_avg_rating + train %>% left_join(movie_ratings, by='title') %>%
pull(movie_avg_diff)
RMSE(model_1_predictions, train$rating)
```

The RMSE taking into account only the movie effect is 0.9423.

\pagebreak
  
### Model 2: User Effect

```{r}
# Calculate difference between each user’s average rating and the overall average rating
user_ratings %>% mutate(user_avg_diff = avg_user_rating - overall_avg_rating) -> user_ratings
head(user_ratings)

```

```{r}
qplot(user_avg_diff, data = user_ratings, bins = 10, color = I("black")) +
labs(title = "Distribution of Average User Rating and Global Average Differences",
x = "Difference Between Average User Rating and Global Average",
y = "Number of Users")
```
As you can see, a lot of users have an average rating close to the global average (difference of 0) and few users have an average rating that is far from the global average (difference of +/- 2). In addition, the average rating for the specific user is more likely to have a positive impact on each rating since there are more positive differences

```{r}
model_2_predictions <- overall_avg_rating + train %>%
left_join(user_ratings, by='userId') %>%
pull(user_avg_diff)
RMSE(model_2_predictions, train$rating)

```
The RMSE taking into account only the user effect is 0.9700, which is higher (worse) than model 1.

\  
  
Finally, I will take into account both movie and user effect.  
 
\pagebreak

### Model 3: Movie & User Effect 
```{r}
model_3_predictions <- train %>%
left_join(movie_ratings, by='title') %>%
left_join(user_ratings, by='userId') %>%
mutate(pred = overall_avg_rating + movie_avg_diff + user_avg_diff) %>%
pull(pred)
RMSE(model_3_predictions, train$rating)
```
The RMSE taking into account both the movie and user effect is 0.8767.

\pagebreak


# Results 

## Model Evaluation

Model                        | RMSE
---------------------------- | -------
Model 1: Movie Effect        | 0.9423
Model 2: User Effect         | 0.9700
Model 3: Movie & User Effect | 0.8768 

Model 3 (Movie & User Effect) has the lowest RMSE. Thus, I will deploy this model to the validation dataset.
  
\  

## Model Deployment 
```{r}
validation_predictions <- validation %>%
left_join(movie_ratings, by='title') %>%
left_join(user_ratings, by='userId') %>%
mutate(pred = overall_avg_rating + movie_avg_diff + user_avg_diff) %>%
pull(pred)
RMSE(validation_predictions, validation$rating)

```
After deploying model 3, which incorporates movie and user effects, the resulting RMSE is 0.885

# Conclusion
In conclusion, taking into account user preferences and a movie's average rating does a better job of predicting ratings than simply taking into account only user effects or only movie effects.

Our model does not take into account changes in user preferences which is a limitation of our model. However, a component can be implemented in future iterations to capture this feature. For example, If we want to  create a rolling average metric that would determine a user's average rating of their 10 most recent ratings. This may better represent user preferences because it takes into account possible changes in user tendencies. However, it may also create a lot of "noise". For example, a user may decide to watch a lot of highly rated movies back-to-back which would skew predictions.

Ideally, we would also like our model to include a component that would capture similarity scores between users. For example, if user A rates movies similar to user B, and user B rated *Jurassic Park* 3 stars, user A should be likely to rate *Jurassic Park* close to 3 stars. Similarly, I would like my model to integrate an element that would capture similarity scores between movies, based on genres. For example, if Drama and War movies tend to be rated higher than other movies, the model should take it into account. However, considering the dataset contains about 10 million ratings, it is challenging to implement these components without significantly slowing down the time it takes for the model to make predictions.