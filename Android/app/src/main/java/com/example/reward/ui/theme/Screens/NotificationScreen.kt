package com.example.reward.ui.theme.Screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.example.reward.data.Composables.NotificationHeader
import com.example.reward.data.Composables.NotificationItem
import com.example.reward.data.Composables.bottombaricon
import com.example.reward.data.Composables.sample.notificationsList


@Composable
fun NotificationScreen() {
    Scaffold(modifier = Modifier, bottomBar = { bottombaricon() }) { paddingValues ->

        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
                .padding(paddingValues)
        )
        {
            NotificationHeader()
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                items(notificationsList) { notification ->
                    NotificationItem(notification)
                }
            }

        }
    }
}
