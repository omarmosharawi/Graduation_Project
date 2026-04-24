package com.example.reward.ui.theme.Screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.example.reward.data.Composables.RankingList
import com.example.reward.data.Composables.bottombaricon
import com.example.reward.data.Composables.rankingHeader

@Composable
fun RankingScreen() {
    Scaffold (modifier = Modifier,bottomBar = {bottombaricon()} ) { paddingValues ->

        Column(
            modifier = Modifier
                 .fillMaxSize()
                .background(Color.White)
                .padding(paddingValues )

        ) {

            rankingHeader()

            RankingList()

            Spacer(modifier = Modifier.weight(1f))

        }
    }
}