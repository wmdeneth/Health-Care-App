import { useEffect, useState } from 'react'
import {
  collection,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  doc,
  serverTimestamp,
  query,
  orderBy,
  getDoc,
  setDoc,
  where,
} from 'firebase/firestore'
import { db } from './firebase'

function App() {
  const [activeTab, setActiveTab] = useState('overview') // 'overview' | 'users' | 'mealTips' | 'notifications' | 'waterSchedules'

  // Meal tips
  const [tips, setTips] = useState([])
  const [tipsLoading, setTipsLoading] = useState(true)
  const [tipsError, setTipsError] = useState('')
  const [form, setForm] = useState({ id: null, title: '', subtitle: '', colorHex: '#FF8A65' })

  // Users
  const [users, setUsers] = useState([])
  const [usersLoading, setUsersLoading] = useState(true)
  const [usersError, setUsersError] = useState('')

  // Admin Notifications
  const [adminNotifications, setAdminNotifications] = useState([])
  const [notificationsLoading, setNotificationsLoading] = useState(true)
  const [notificationForm, setNotificationForm] = useState({ title: '', message: '', type: 'global' })

  // Meal tips stream
  useEffect(() => {
    const q = query(collection(db, 'mealTips'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }))
        setTips(data)
        setTipsLoading(false)
      },
      (err) => {
        console.error('Failed to load meal tips', err)
        setTipsError('Failed to load meal tips')
        setTipsLoading(false)
      },
    )

    return () => unsub()
  }, [])

  // Users stream
  useEffect(() => {
    const usersQuery = query(collection(db, 'users'))
    const unsub = onSnapshot(
      usersQuery,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }))
        setUsers(data)
        setUsersLoading(false)
      },
      (err) => {
        console.error('Failed to load users', err)
        setUsersError('Failed to load users')
        setUsersLoading(false)
      },
    )

    return () => unsub()
  }, [])

  // Admin Notifications stream
  useEffect(() => {
    const q = query(collection(db, 'adminNotifications'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }))
        setAdminNotifications(data)
        setNotificationsLoading(false)
      },
      (err) => {
        console.error('Failed to load admin notifications', err)
        setNotificationsLoading(false)
      }
    )

    return () => unsub()
  }, [])

  const resetForm = () =>
    setForm({ id: null, title: '', subtitle: '', colorHex: '#FF8A65' })

  const handleChange = (e) => {
    const { name, value } = e.target
    setForm((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const title = form.title.trim()
    const subtitle = form.subtitle.trim()
    const colorHex = form.colorHex.trim() || '#FF8A65'

    if (!title) {
      setTipsError('Title is required')
      return
    }

    try {
      if (form.id == null) {
        await addDoc(collection(db, 'mealTips'), {
          title,
          subtitle,
          colorHex,
          createdAt: serverTimestamp(),
        })
      } else {
        await updateDoc(doc(db, 'mealTips', form.id), {
          title,
          subtitle,
          colorHex,
        })
      }
      resetForm()
      setTipsError('')
    } catch (err) {
      setTipsError(err.message || 'Failed to save meal tip')
    }
  }

  const handleEdit = (tip) => {
    setForm({
      id: tip.id,
      title: tip.title ?? '',
      subtitle: tip.subtitle ?? '',
      colorHex: tip.colorHex ?? '#FF8A65',
    })
  }

  const handleDelete = async (id) => {
    try {
      await deleteDoc(doc(db, 'mealTips', id))
      if (form.id === id) resetForm()
    } catch (err) {
      setTipsError(err.message || 'Failed to delete meal tip')
    }
  }

  // Admin Notification Handlers
  const handleNotificationChange = (e) => {
    const { name, value } = e.target
    setNotificationForm(prev => ({ ...prev, [name]: value }))
  }

  const handleNotificationSubmit = async (e) => {
    e.preventDefault()
    if (!notificationForm.title || !notificationForm.message) {
      alert('Title and message are required')
      return
    }

    try {
      await addDoc(collection(db, 'adminNotifications'), {
        ...notificationForm,
        createdAt: serverTimestamp(),
      })
      setNotificationForm({ title: '', message: '', type: 'global' })
    } catch (err) {
      console.error('Failed to send notification', err)
      alert('Failed to send notification: ' + err.message)
    }
  }

  const handleDeleteNotification = async (id) => {
    if (window.confirm('Are you sure you want to delete this notification?')) {
      try {
        await deleteDoc(doc(db, 'adminNotifications', id))
      } catch (err) {
        alert('Failed to delete notification')
      }
    }
  }

  const injectTestData = async () => {
    try {
      await addDoc(collection(db, 'users'), {
        nickname: 'Test User',
        heightCm: 175,
        weightKg: 70,
        createdAt: serverTimestamp(),
      })

      await addDoc(collection(db, 'mealTips'), {
        title: 'Drink water!',
        subtitle: 'Drinking a glass of water before meals helps digestion.',
        colorHex: '#3B82F6',
        createdAt: serverTimestamp(),
      })
      alert('Test data injected.')
    } catch (err) {
      alert('Failed to inject test data.')
    }
  }

  // Water Schedules
  const [editingUser, setEditingUser] = useState(null)
  const [scheduleForm, setScheduleForm] = useState({
    waterEnabled: true,
    waterStartHour: 8,
    waterEndHour: 22,
    dailyWaterGoal: 2000,
  })

  // (Removed handleEditSchedule for conciseness as user asked to separate but focus on notifications screen)

  return (
    <div className="admin-root d-flex min-vh-100">
      {/* Sidebar */}
      <aside className="admin-sidebar d-flex flex-column p-3 gap-3">
        <div className="d-flex align-items-center gap-2 admin-logo mb-2">
          <span className="admin-logo-dot" />
          <span className="fw-semibold">TestApp3 Admin</span>
        </div>

        <nav className="nav nav-pills flex-column gap-2">
          <button className={`nav-link admin-nav-link ${activeTab === 'overview' ? 'active' : ''}`} onClick={() => setActiveTab('overview')}>Overview</button>
          <button className={`nav-link admin-nav-link ${activeTab === 'users' ? 'active' : ''}`} onClick={() => setActiveTab('users')}>Users</button>
          <button className={`nav-link admin-nav-link ${activeTab === 'waterSchedules' ? 'active' : ''}`} onClick={() => setActiveTab('waterSchedules')}>Water Schedules</button>
          <button className={`nav-link admin-nav-link ${activeTab === 'mealTips' ? 'active' : ''}`} onClick={() => setActiveTab('mealTips')}>Meal Tips</button>
          <button className={`nav-link admin-nav-link ${activeTab === 'notifications' ? 'active' : ''}`} onClick={() => setActiveTab('notifications')}>Push Notifications</button>
        </nav>
      </aside>

      {/* Main content */}
      <main className="admin-main flex-fill">
        <header className="admin-topbar d-flex justify-content-between align-items-center">
          <div className="d-flex flex-column">
            <div className="admin-topbar-title">Control Center</div>
            <small className="text-muted">{activeTab.charAt(0).toUpperCase() + activeTab.slice(1)} management</small>
          </div>
          <button className="btn btn-sm btn-outline-secondary" onClick={injectTestData}>Inject Test Data</button>
        </header>

        <div className="container-fluid py-4">
          {activeTab === 'overview' && (
            <div className="row g-3">
              <div className="col-md-4">
                <div className="admin-stat-card">
                  <div className="admin-stat-label">Total Users</div>
                  <div className="admin-stat-value">{users.length}</div>
                </div>
              </div>
              <div className="col-md-4">
                <div className="admin-stat-card">
                  <div className="admin-stat-label">Admin Notifications</div>
                  <div className="admin-stat-value">{adminNotifications.length}</div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'notifications' && (
            <div className="row g-3">
              <div className="col-lg-5">
                <div className="admin-section-card">
                  <h2 className="admin-section-title">Send Broadcast</h2>
                  <form onSubmit={handleNotificationSubmit}>
                    <div className="mb-3">
                      <label className="form-label">Title</label>
                      <input name="title" value={notificationForm.title} onChange={handleNotificationChange} className="form-control" placeholder="Update title" />
                    </div>
                    <div className="mb-3">
                      <label className="form-label">Message</label>
                      <textarea name="message" value={notificationForm.message} onChange={handleNotificationChange} className="form-control" rows={3} placeholder="Notification content" />
                    </div>
                    <button type="submit" className="btn btn-primary w-100">Broadcast Notification</button>
                  </form>
                </div>
              </div>
              <div className="col-lg-7">
                <div className="admin-section-card">
                  <h2 className="admin-section-title">Message History</h2>
                  <div className="table-responsive">
                    <table className="table table-dark-soft table-sm">
                      <thead>
                        <tr>
                          <th>Date</th>
                          <th>Title</th>
                          <th>Content</th>
                          <th>Action</th>
                        </tr>
                      </thead>
                      <tbody>
                        {adminNotifications.map(n => (
                          <tr key={n.id}>
                            <td>{n.createdAt?.toDate().toLocaleDateString()}</td>
                            <td>{n.title}</td>
                            <td>{n.message}</td>
                            <td>
                              <button className="btn btn-sm btn-outline-danger" onClick={() => handleDeleteNotification(n.id)}>Delete</button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'users' && (
            <div className="admin-section-card">
              <h2 className="admin-section-title">All Users</h2>
              <div className="table-responsive">
                <table className="table table-dark-soft">
                  <thead>
                    <tr>
                      <th>UID</th>
                      <th>Name</th>
                      <th>Stats</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map(u => (
                      <tr key={u.id}>
                        <td>{u.id}</td>
                        <td>{u.nickname || 'Unknown'}</td>
                        <td>{u.weightKg}kg / {u.heightCm}cm</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'mealTips' && (
            <div className="row g-3">
              <div className="col-lg-4">
                <div className="admin-section-card">
                  <h2 className="admin-section-title">Add Tip</h2>
                  <form onSubmit={handleSubmit}>
                    <input name="title" value={form.title} onChange={handleChange} className="form-control mb-2" placeholder="Title" />
                    <textarea name="subtitle" value={form.subtitle} onChange={handleChange} className="form-control mb-2" placeholder="Content" />
                    <button className="btn btn-primary w-100">Save Tip</button>
                  </form>
                </div>
              </div>
              <div className="col-lg-8">
                <div className="admin-section-card">
                  <table className="table table-dark-soft">
                    <tbody>
                      {tips.map(t => (
                        <tr key={t.id}>
                          <td>{t.title}</td>
                          <td><button className="btn btn-sm btn-outline-danger" onClick={() => handleDelete(t.id)}>Delete</button></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'waterSchedules' && (
            <div className="admin-section-card">
              <h2 className="admin-section-title">User Water Schedules</h2>
              <table className="table table-dark-soft">
                <thead>
                  <tr><th>User</th><th>Goal</th><th>Current</th><th>Window</th></tr>
                </thead>
                <tbody>
                  {users.map(u => (
                    <tr key={u.id}>
                      <td>{u.nickname}</td>
                      <td>{u.dailyWaterGoal || 'Auto'}ml</td>
                      <td>{u.currentIntake || 0}ml</td>
                      <td>{u.waterStartHour}:00 - {u.waterEndHour}:00</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </main>
    </div>
  )
}

export default App
