import React from "react"
import { DashboardProps } from "../types"

const MenuItem = ({ dashboard, currentDashboard, includeH1 }: { dashboard: DashboardProps, currentDashboard: DashboardProps, includeH1: boolean }) => {
  if (dashboard.name === currentDashboard.name) {
    if(includeH1) {
      return <h1><span className="link link--primary link--active">{dashboard.name}</span></h1>
    } else {
      return <a className="link link--primary link--active" href={dashboard.url}><span>{dashboard.name}</span></a>
    }
  }else {
    return <a className="link link--primary" href={dashboard.url}><span>{dashboard.name}</span></a>
  }
}

export default MenuItem;