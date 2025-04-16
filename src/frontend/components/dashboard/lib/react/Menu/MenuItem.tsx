import React from "react"
import { DashboardProps } from "../types"
import { Nav } from "react-bootstrap"

const MenuItem = ({ dashboard, currentDashboard, includeH1 }: { dashboard: DashboardProps, currentDashboard: DashboardProps, includeH1: boolean }) => {
  if (dashboard.name === currentDashboard.name) {
    if (includeH1) {
      return <Nav.Item>
        <Nav.Link active href={dashboard.url}><h1><span>{dashboard.name}</span></h1></Nav.Link>
      </Nav.Item>
    } else {
      return <Nav.Item>
        <Nav.Link active href={dashboard.url}><span>{dashboard.name}</span></Nav.Link>
      </Nav.Item>
    }
  } else {
    return <Nav.Item>
      <Nav.Link href={dashboard.url}><span>{dashboard.name}</span></Nav.Link>
    </Nav.Item>
  }
}

export default MenuItem;